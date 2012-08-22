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

# FIXME: Is this require here really needed?
#
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
  has_and_belongs_to_many :realms, :uniq => true
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  # Calidation of credentials is done in provider_account validation,
  # :validate => false prevents nested_attributes from validation
  has_many :credentials, :dependent => :destroy, :validate => false
  accepts_nested_attributes_for :credentials

  # eventually, this might be "has_many", but first pass is one-to-one
  has_one :config_server, :dependent => :destroy

  has_many :provider_priority_group_elements, :as => :value, :dependent => :destroy

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
  validates :priority,
            :numericality => { :only_integer => true,
                               :greater_than_or_equal_to => -100,
                               :less_than_or_equal_to => 100 },
            :allow_blank => true

  before_create :populate_profiles_and_validate
  after_create :populate_realms_and_validate
  before_destroy :destroyable?

  scope :enabled, lambda { where(:provider_id => Provider.enabled) }

  # We set credentials hash as protected so that it is not set during mass assign on new
  # This is to avoid the scenario where the credentials are set before provider which
  # will result in an exception.
  attr_protected :credentials_hash

  def validate_presence_of_credentials
    provider.provider_type.credential_definitions.each do |cd|
      next unless credentials_hash[cd.name].blank?
      errors.add(:base, "#{I18n.t("provider_accounts.credentials.labels.#{cd.label}")} "+
                 " #{I18n.t('errors.messages.blank')}")
    end
  end

  def validate_credentials
    begin
      errors.add(:base, I18n.t('provider_accounts.errors.invalid_credentials')) unless valid_credentials?
      # FIXME: The rescue block should have list of exceptions we want to
      # capture. Otherwise *all* exceptions (including unwanted are captured)
    rescue
      errors.add(:base, I18n.t('provider_accounts.errors.exception_while_validating'))
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

  def perm_ancestors
    super + [provider]
  end
  def self.additional_privilege_target_types
    [Quota]
  end

  def destroyable?
    instances.empty? || instances.all? { |i| i.destroyable? }
  end

  def connect
    begin
      opts = {
        :username => credentials_hash['username'],
        :password => credentials_hash['password'],
        :driver => provider.provider_type.deltacloud_driver
      }
      opts[:provider] = provider.deltacloud_provider if provider.deltacloud_provider
      client = DeltaCloud.new(credentials_hash['username'],
                              credentials_hash['password'],
                              provider.url)
      client.with_config(opts)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def pools
    instances.map { |i| i.pool }
  end

  def name
    label.blank? ? credentials_hash['username'] : label
  end

  def as_json(options={})
    super(options).merge(:provider_name => provider.name)
  end

  def populate_profiles_and_validate
    begin
      populate_hardware_profiles
    rescue
      errors.add(:base, I18n.t("provider_accounts.errors.populate_hardware_profiles_failed", :message => $!.message))
      false
    end
  end

  def populate_realms_and_validate
    begin
      populate_realms
    rescue => e
      errors.add(:base, I18n.t("provider_accounts.errors.populate_realms_failed", :message => $!.message))
      raise e
    end
  end

  def populate_realms
    provider.populate_realms
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
    # The list is ordered by labels. That way we guarantee that the resulting
    # XML is always the same which makes it easier to verify in tests.
    credentials.map do |c|
      { :label => c.credential_definition.label.downcase.split.join('_'),
        :value => c.value }
    end.sort { |a, b| a[:label] <=> b[:label] }
  end

  def credentials_hash
    credentials.inject({}) do |cred_hash, c|
      cred_hash[c.credential_definition.name] = c.value
      cred_hash
    end
  end

  def credentials_hash=(hash={})
    return if !provider
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
      credentials.detect do |c|
        c.credential_definition_id == cd.id
      end || Credential.new(:credential_definition => cd, :value => nil)
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

  def self.group_by_type(pool_family)
    res = {}
    family_accounts = pool_family.nil? ? [] : pool_family.provider_accounts
    ProviderAccount.enabled.each do |account|
      ptype = account.provider.provider_type
      res[ptype.deltacloud_driver] ||= {:type => ptype, :accounts => []}
      res[ptype.deltacloud_driver][:accounts] << {:account => account,
                                                  :included => family_accounts.include?(account)}
    end
    res.each do |driver, group|
      group[:included] = (group[:accounts].count{|a| a[:included]} > 0)
    end
    res
  end

  # This is to allow us to look up the ProviderAccount for a given provider image
  def self.find_by_provider_name_and_login(provider_name, login)
    begin
      provider = Provider.find_by_name(provider_name)
      credential_definition = CredentialDefinition.find_by_provider_type_id_and_name(provider.provider_type.id, 'username')
      where_hash = {:credential_definition_id => credential_definition.id, :value => login}
      cred = Credential.where(where_hash).includes(:provider_account).where('provider_accounts.provider_id' => provider.id)
      # The above should always return an array with zero (if an error) or one element, but rescue nil to be safe:
      cred.first.provider_account rescue nil
    rescue
      nil
    end
  end

  def instance_matches(instance, matched, errors)
    if !provider.enabled?
      errors << I18n.t('instances.errors.must_be_enabled', :account_name => name)
    elsif !provider.available?
      errors << I18n.t('instances.errors.provider_not_available', :account_name => name)
    elsif quota.reached?
      errors << I18n.t('instances.errors.provider_account_quota_reached', :account_name => name)
    # match_provider_hardware_profile returns a single provider
    # hardware_profile that can satisfy the input hardware_profile
    elsif !(hwp = HardwareProfile.match_provider_hardware_profile(provider, instance.hardware_profile))
      errors << I18n.t('instances.errors.hw_profile_match_not_found', :account_name => name)
    elsif (account_images = instance.provider_images_for_match(self)).empty?
      errors << I18n.t('instances.errors.image_not_pushed_to_provider', :account_name => name)
    elsif instance.requires_config_server? and config_server.nil?
      errors << I18n.t('instances.errors.no_config_server_available', :account_name => name)
    else
      account_images.each do |pi|
        if not instance.frontend_realm.nil?
          brealms = instance.frontend_realm.realm_backend_targets.select do |brealm_target|
            brealm_target.target_provider == provider
          end
          if brealms.empty?
            errors << I18n.t(
              'instances.errors.realm_not_mapped',
              :account_name => name,
              :frontend_realm_name => instance.frontend_realm.name
            )
            next
          end
          brealms.each do |brealm_target|
            # add match if realm is mapped to provider or if it's mapped to
            # backend realm which is available and is accessible for this
            # provider account
            if (brealm_target.target_realm.nil? ||
                (brealm_target.target_realm.available && realms.include?(brealm_target.target_realm)))
              matched << InstanceMatch.new(
                :pool_family => instance.pool.pool_family,
                :provider_account => self,
                :hardware_profile => hwp,
                :provider_image => pi.target_identifier,
                :realm => brealm_target.target_realm,
                :instance => instance
              )
            end
          end
        else
          matched << InstanceMatch.new(
            :pool_family => instance.pool.pool_family,
            :provider_account => self,
            :hardware_profile => hwp,
            :provider_image => pi.target_identifier,
            :realm => nil,
            :instance => instance
          )
        end
      end
    end
  end

  # TODO: it would be much better to have this method in image model,
  # but we don't have suitable image model ATM.
  def image_status(image)
    target = provider.provider_type.deltacloud_driver

    builder = Aeolus::Image::Factory::Builder.first
    return :building if builder.find_active_build_by_imageid(image.id, target)

    build = image.latest_pushed_or_unpushed_build
    return :not_built unless build

    target_image = build.target_images.find { |ti| ti.target == target }
    return :not_built unless target_image

    return :pushing if builder.find_active_push(target_image.id,
                                                provider.name,
                                                credentials_hash["username"])

    provider_image = target_image.find_provider_image_by_provider_and_account(
        provider.name, credentials_hash["username"]).first

    provider_image ? :pushed : :not_pushed
  end

  def to_polymorphic_path_param(polymorphic_path_extras)
    [provider, self]
  end

  private

  def self.apply_search_filter(search)
    return scoped unless search
    includes(:provider => [:provider_type]).where("lower(provider_accounts.label) LIKE :search OR lower(providers.name) LIKE :search OR lower(provider_types.name) LIKE :search", :search => "%#{search.downcase}%")
  end
end
