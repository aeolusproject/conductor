# == Schema Information
# Schema version: 20110207110131
#
# Table name: provider_accounts
#
#  id             :integer         not null, primary key
#  label          :string(255)     not null
#  username       :string(255)     not null
#  password       :string(255)     not null
#  provider_id    :integer         not null
#  quota_id       :integer
#  lock_version   :integer         default(0)
#  account_number :string(255)
#  x509_cert_priv :text
#  x509_cert_pub  :text
#  created_at     :datetime
#  updated_at     :datetime
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
require 'sunspot_rails'

class ProviderAccount < ActiveRecord::Base
  include PermissionedObject

  searchable do
    text :name, :as => :code_substring
    text :username, :as => :code_substring
  end

  # Relations
  belongs_to :provider
  belongs_to :quota, :autosave => true
  has_many :instances
  has_and_belongs_to_many :pool_families
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  has_one :instance_key, :as => :instance_key_owner, :dependent => :destroy

  # Helpers
  attr_accessor :x509_cert_priv_file, :x509_cert_pub_file

  # Validations
  validates_presence_of :provider
  validates_presence_of :label
  validates_presence_of :username
  validates_uniqueness_of :username, :scope => :provider_id
  validates_presence_of :password
  validates_presence_of :account_number,:if => Proc.new{ |account| account.provider.provider_type == Provider::AWS}
  validate :validate_presence_of_x509_certs
  validate :validate_credentials

  # We're using this instead of <tt>validates_presence_of</tt> helper because
  # we want to show errors on different attributes ending with '_file'.
  def validate_presence_of_x509_certs
    if self.provider.provider_type == Provider::AWS
      errors.add(:x509_cert_pub_file, "can't be blank") if x509_cert_pub.blank?
      errors.add(:x509_cert_priv_file, "can't be blank") if x509_cert_priv.blank?
    end
  end

  def validate_credentials
    unless valid_credentials?
      errors.add(:base, "Login Credentials are Invalid for this Provider")
    end
  end

  # Hooks
  before_destroy :destroyable?
  before_validation :read_x509_files

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

  def read_x509_files
    if x509_cert_pub_file.respond_to?(:read)
      x509_cert_pub_file.rewind # Sometimes the file has to rewind, becuase something already read from it.
      self.x509_cert_pub = x509_cert_pub_file.read
    end
    if x509_cert_priv_file.respond_to?(:read)
      x509_cert_priv_file.rewind
      self.x509_cert_priv = x509_cert_priv_file.read
    end
  end

  def connect
    begin
      return DeltaCloud.new(username, password, provider.url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def self.find_or_create(account)
    a = ProviderAccount.find_by_username_and_provider_id(account["username"], account["provider_id"])
    return a.nil? ? ProviderAccount.new(account) : a
  end

  def pools
    pools = []
    instances.each do |instance|
      pools << instance.pool
    end
  end

  def name
    label.blank? ? username : label
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

          frontend_realm = Realm.new(:external_key => ar_realm.external_key,
                                     :name => ar_realm.name,
                                     :provider_id => nil)

          available_realms = Realm.frontend.find(:all, :conditions => {
            :external_key => frontend_realm.external_key })

          if available_realms.empty?
            frontend_realm.backend_realms << ar_realm
            frontend_realm.save!
          else
            available_realms.each do |r|
              r.backend_realms << ar_realm
            end
          end
        end
      end
    end
  end

  def valid_credentials?
    DeltaCloud::valid_credentials?(username, password, provider.url)
  end

  def build_credentials
    xml = Nokogiri::XML <<EOT
<?xml version="1.0"?>
<provider_credentials>
  <ec2_credentials>
    <account_number></account_number>
    <access_key></access_key>
    <secret_access_key></secret_access_key>
    <certificate></certificate>
    <key></key>
  </ec2_credentials>
</provider_credentials>
EOT
    node = xml.at_xpath('/provider_credentials/ec2_credentials')
    node.at_xpath('./account_number').content = account_number
    node.at_xpath('./access_key').content = username
    node.at_xpath('./secret_access_key').content = password
    node.at_xpath('./certificate').content = x509_cert_pub
    node.at_xpath('./key').content = x509_cert_priv
    return xml.to_s
  end

  def generate_auth_key
    client = connect
    return nil unless client && client.feature?(:instances, :authentication_key)
    client.create_key(:name => "#{self.name}_#{Time.now.to_i}_key_#{self.object_id}")
  end
end
