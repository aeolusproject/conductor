# == Schema Information
# Schema version: 20110309105149
#
# Table name: provider_accounts
#
#  id           :integer         not null, primary key
#  label        :string(255)     not null
#  provider_id  :integer         not null
#  quota_id     :integer
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

 #
# Copyright (C) 2009 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'nokogiri'

class ProviderAccount < ActiveRecord::Base
  include PermissionedObject

  # Relations
  belongs_to :provider
  belongs_to :quota, :autosave => true
  has_many :instances
  has_and_belongs_to_many :pool_families
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  has_one :instance_key, :as => :instance_key_owner, :dependent => :destroy
  # validation of credentials is done in provider_account validation, :validate => false prevents nested_attributes from validation
  has_many :credentials, :dependent => :destroy, :validate => false
  accepts_nested_attributes_for :credentials

  # Helpers
  attr_accessor :x509_cert_priv_file, :x509_cert_pub_file

  # Validations
  validates_presence_of :provider
  validates_presence_of :label
  validates_uniqueness_of :label
  validate :validate_presence_of_credentials
  validate :validate_credentials
  validate :validate_unique_username
  before_create :no_account?
  before_destroy :destroyable?

  def validate_presence_of_credentials
    provider.provider_type.credential_definitions.each do |cd|
      errors.add(:base, "#{cd.label} can't be blank") if credentials_hash[cd.name].blank?
    end
  end

  def validate_credentials
    unless valid_credentials?
      errors.add(:base, "Login Credenials are Invalid for this Provider")
    end
  end

  def validate_unique_username
    cid = CredentialDefinition.find_by_name('username', :conditions => {:provider_type_id => provider.provider_type.id})
    Credential.all(:conditions => {:value => credentials_hash['username'], :credential_definition_id => cid}).each do |c|
      if c.provider_account.provider == self.provider && c.provider_account_id != self.id
        errors.add(:base, "Username has already been taken")
        return false
      end
    end
    return true
  end

  def no_account?
    #if provider.provider_accounts.empty?
    if provider.provider_accounts.empty?
      return true
    else
      errors.add(:base, "Only one account is supported per provider")
      return false
    end
  end

  def object_list
    super << provider
  end
  class << self
    alias orig_list_for_user_include list_for_user_include
    alias orig_list_for_user_conditions list_for_user_conditions
  end

  def self.list_for_user_include
    includes = orig_list_for_user_include
    includes << { :provider => {:permissions => {:role => :privileges}}}
    includes
  end

  def self.list_for_user_conditions
    "(#{orig_list_for_user_conditions}) or
     (permissions_providers.user_id=:user and
      privileges_roles.target_type=:target_type and
      privileges_roles.action=:action)"
  end

  def destroyable?
    instances.empty?
  end

  def connect
    begin
      return DeltaCloud.new(credentials_hash['username'], credentials_hash['password'], provider.url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def pools
    pools = []
    instances.each do |instance|
      pools << instance.pool
    end
  end

  def name
    label.blank? ? credentials_hash['username'] : label
  end

  # FIXME: for already-mapped accounts, update rather than add new
  def populate_realms
    client = connect
    realms = client.realms
    # FIXME: this should probably be in the same transaction as cloud_account.save
    self.transaction do
      realms.each do |realm|
        #ignore if it exists
        #FIXME: we need to handle keeping in sync forupdates as well as
        # account permissions
        unless Realm.find_by_external_key_and_provider_id(realm.id,
                                                          provider.id)
          ar_realm = Realm.new(:external_key => realm.id,
                               :name => realm.name ? realm.name : realm.id,
                               :provider_id => provider.id)
          ar_realm.save!
        end
      end
    end
  end

  def valid_credentials?
    if credentials_hash['username'].blank? || credentials_hash['password'].blank?
      return false
    end
    DeltaCloud::valid_credentials?(credentials_hash['username'].to_s, credentials_hash['password'].to_s, provider.url)
  end

  def build_credentials
    doc = Nokogiri::XML('')
    doc.root = Nokogiri::XML::Node.new('provider_credentials', doc)
    root = doc.root.at_xpath('/provider_credentials')

    credential_node_name = provider.provider_type.codename + '_credentials'
    credential_node = Nokogiri::XML::Node.new(credential_node_name, doc)
    root << credential_node

    creds_label_hash.each do |h|
      element = Nokogiri::XML::Node.new(h[:label], doc)
      element.content = h[:value]
      credential_node << element
    end
    doc
  end

  def creds_label_hash
    label_value_pairs = credentials.map do |c|
      { :label => c.credential_definition.label.downcase.split.join('_'),
        :value => c.value }
    end

    # The list is ordered by labels. That way we guarantee that the resulting
    # XML is always the same which makes it easier to verify in tests.
    label_value_pairs.sort { |a, b| a[:label] <=> b[:label] }
  end

  def generate_auth_key
    client = connect
    return nil unless client && client.feature?(:instances, :authentication_key)
    client.create_key(:name => "#{self.name}_#{Time.now.to_i}_key_#{self.object_id}")
  end

  def credentials_hash
      @credentials_hash = {}
     # Credential.all(:conditions => {:provider_account_id => id}, :include => :credential_definition).each do |cred|
      credentials.each do |cred|
        @credentials_hash[cred.credential_definition.name] = cred.value
      end
    @credentials_hash
  end

  def credentials_hash=(hash={})
    cred_defs = provider.provider_type.credential_definitions
    hash.each do |k,v|
      cred_def = cred_defs.detect {|d| d.name == k.to_s}
      raise "Key #{k} not found" unless cred_def
      unless cred = credentials.detect {|c| c.credential_definition_id == cred_def.id}
          cred = Credential.new(:provider_account_id => id, :credential_definition_id => cred_def.id)
          credentials << cred
      end
      # we need to handle uploaded files:
      cred.value = v.respond_to?(:read) ? v.read : v
    end
  end

  def all_credentials(prov)
    prov.provider_type.credential_definitions.map do |cd|
      credentials.detect {|c| c.credential_definition_id == cd.id} || Credential.new(:credential_definition => cd, :value => nil)
    end
  end
end
