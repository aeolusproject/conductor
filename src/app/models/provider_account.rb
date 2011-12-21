#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'nokogiri'

class ProviderAccount < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  include PermissionedObject

  # Relations
  belongs_to :provider
  belongs_to :quota, :autosave => true, :dependent => :destroy
  has_many :instances
  has_and_belongs_to_many :pool_families, :uniq => true
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  # validation of credentials is done in provider_account validation, :validate => false prevents nested_attributes from validation
  has_many :credentials, :dependent => :destroy, :validate => false
  accepts_nested_attributes_for :credentials
  # eventually, this might be "has_many", but first pass is one-to-one
  has_one :config_server, :dependent => :destroy

  # Helpers
  attr_accessor :x509_cert_priv_file, :x509_cert_pub_file

  # Validations
  validates_presence_of :provider
  validates_presence_of :label
  validates_uniqueness_of :label
  validates_presence_of :quota
  validate :validate_presence_of_credentials
  validate :validate_credentials
  validate :validate_unique_username
  before_create :no_account?
  before_destroy :destroyable?

  scope :enabled, where(:provider_id => Provider.enabled)

  def validate_presence_of_credentials
    provider.provider_type.credential_definitions.each do |cd|
      errors.add(:base, "#{cd.label} can't be blank") if credentials_hash[cd.name].blank?
    end
  end

  def validate_credentials
    unless valid_credentials?
      errors.add(:base, "Login Credentials are Invalid for this Provider")
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
    instances.empty? || instances.all? { |i| i.destroyable? }
  end

  def connect
    begin
      opts = {:username => credentials_hash['username'],
              :password => credentials_hash['password'],
              :driver => provider.provider_type.deltacloud_driver }
      opts[:provider] = provider.deltacloud_provider if provider.deltacloud_provider
      client = DeltaCloud.new(credentials_hash['username'],
                              credentials_hash['password'],
                              provider.url)
      return client.with_config(opts)
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

  def populate_realms
    client = connect
    deltacloud_realms = client.realms
    conductor_realms = Realm.where(:provider_id => provider.id)
    deltacloud_realm_ids = deltacloud_realms.collect{|r| r.id}
    conductor_realm_ids = conductor_realms.collect{|r| r.external_key}

    # I don't know if this transaction is really necessary, but it was here so let's keep it.
    self.transaction do
      # Delete anything in Conductor that's not in Deltacloud
      conductor_realms.each do |c_realm|
        c_realm.destroy unless deltacloud_realm_ids.include?(c_realm.external_key)
      end

      # Add anything in Deltacloud to Conductor if it's not already there
      deltacloud_realms.each do |d_realm|
        unless conductor_realm_ids.include?(d_realm.id)
          ar_realm = Realm.new(:external_key => d_realm.id,
                                 :name => d_realm.name ? d_realm.name : d_realm.id,
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
      opts = {:driver => provider.provider_type.deltacloud_driver }
      opts[:provider] = provider.deltacloud_provider if provider.deltacloud_provider
    DeltaCloud::valid_credentials?(credentials_hash['username'].to_s,
                                   credentials_hash['password'].to_s,
                                   provider.url,
                                   opts)
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

  # Some providers don't allow fetching HWPs without authentication,
  # so we cannot populate them until after a provider account is added.
  def populate_hardware_profiles
    # If the provider already has hardware profiles, do not refetch them:
    return provider.hardware_profiles if provider.hardware_profiles.present?
    # FIXME: once API has hw profiles, change the below
    hardware_profiles = connect.hardware_profiles
    _provider = provider
    self.transaction do
      hardware_profiles.each do |hardware_profile|
        ar_hardware_profile = HardwareProfile.new(:external_key =>
                                                  hardware_profile.id,
                                                  :name => hardware_profile.id,
                                                  :provider_id => _provider.id)
        ar_hardware_profile.add_properties(hardware_profile)
        ar_hardware_profile.save!
      end
    end
  end

  # Returns XML representation of ProviderAccount
  #
  # @param [Hash] options Options hash
  # @option options [Boolean] :with_credentials (false) Whether to include credentials or not
  # @return [String] XML
  def to_xml(options = {})
    with_credentials = options[:with_credentials] || false

    doc = Nokogiri::XML('')
    doc.root = Nokogiri::XML::Node.new('provider_account', doc)
    root = doc.root.at_xpath('/provider_account')

    node = Nokogiri::XML::Node.new('name', doc)
    node.content = self.name
    root << node

    node = Nokogiri::XML::Node.new('provider', doc)
    node.content = self.provider.name
    root << node

    node = Nokogiri::XML::Node.new('provider_type', doc)
    node.content = self.provider.provider_type.deltacloud_driver
    root << node

    if with_credentials
      credential_node_name = provider.provider_type.deltacloud_driver + '_credentials'
      credential_node = Nokogiri::XML::Node.new(credential_node_name, doc)
      node = Nokogiri::XML::Node.new('provider_credentials', doc)
      node << credential_node
      root << node

      creds_label_hash.each do |h|
        element = Nokogiri::XML::Node.new(h[:label], doc)
        element.content = h[:value]
        credential_node << element
      end
    end

    doc.root.to_xml
  end

  def self.xml_export(accounts)
    doc = Nokogiri::XML('')
    doc.root = Nokogiri::XML::Node.new('provider_accounts', doc)
    root = doc.root.at_xpath('/provider_accounts')
    accounts.each do |account|
      root << account.to_xml
    end
    doc.to_xml
  end

  PRESET_FILTERS_OPTIONS = []

  def self.group_by_type(user)
    res = {}
    ProviderAccount.list_for_user(user, Privilege::VIEW).each do |account|
      ptype = account.provider.provider_type
      res[ptype.deltacloud_driver] ||= {:type => ptype, :accounts => []}
      res[ptype.deltacloud_driver][:accounts] << account
    end
    res
  end

  def warehouse_id
    # TODO: provider_account_identifier is not set for 'mock' provider images
    # in warehouse, provider_image is supposed to be pushed to all mock provider
    # accounts then
    if provider.provider_type.deltacloud_driver == 'mock'
      return nil
    else
      return credentials_hash['username']
    end
  end

  # This is to allow us to look up the ProviderAccount for a given provider image
  def self.find_by_provider_name_and_login(provider_name, login)
    begin
      provider = Provider.find_by_name(provider_name)
      credential_definition = CredentialDefinition.find_by_provider_type_id_and_name(provider.provider_type.id, 'username')
      Credential.find_by_credential_definition_id_and_value(credential_definition.id, login).provider_account
    rescue
      nil
    end
  end

  def instance_matches(instance, matched, errors)
    if !provider.enabled?
      errors << I18n.t('instances.errors.must_be_enabled', :account_name => name)
    elsif quota.reached?
      errors << I18n.t('instances.errors.provider_account_quota_reached', :account_name => name)
    # match_provider_hardware_profile returns a single provider
    # hardware_profile that can satisfy the input hardware_profile
    elsif !(hwp = HardwareProfile.match_provider_hardware_profile(provider, instance.hardware_profile))
      errors << I18n.t('instances.errors.hw_profile_match_not_found', :account_name => name)
    elsif (account_images = instance.provider_images_for_match(provider)).empty?
      errors << I18n.t('instances.errors.image_not_pushed_to_provider', :account_name => name)
    elsif instance.requires_config_server? and config_server.nil?
      errors << I18n.t('instances.errors.no_config_server_available', :account_name => name)
    else
      account_images.each do |pi|
        if not instance.frontend_realm.nil?
          brealms = instance.frontend_realm.realm_backend_targets.select {|brealm_target| brealm_target.target_provider == provider}
          if brealms.empty?
            errors << I18n.t('instances.errors.realm_not_mapped', :frontend_realm_name => instance.frontend_realm.name)
            next
          end
          brealms.each do |brealm_target|
            matched << Instance::Match.new(instance.pool.pool_family, self, hwp, pi, brealm_target.target_realm)
          end
        else
          matched << Instance::Match.new(instance.pool.pool_family, self, hwp, pi, nil)
        end
      end
    end
  end

  private

  def self.apply_search_filter(search)
    if search
      includes(:provider => [:provider_type]).where("provider_accounts.label ILIKE :search OR providers.name ILIKE :search OR provider_types.name ILIKE :search", :search => "%#{search}%")
    else
      scoped
    end
  end
end
