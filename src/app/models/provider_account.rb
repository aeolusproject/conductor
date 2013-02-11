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

  before_destroy :check_destroyable_instances!
  before_destroy :check_provider_images!
  before_destroy :remove_pool_family_assoc

  # Relations
  belongs_to :provider
  belongs_to :quota, :autosave => true, :dependent => :destroy
  has_many :instances
  has_and_belongs_to_many :pool_families, :uniq => true
  has_and_belongs_to_many :provider_realms, :uniq => true
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"
  has_many :credentials, :dependent => :destroy
  # eventually, this might be "has_many", but first pass is one-to-one
  has_one :config_server, :dependent => :destroy
  has_many :provider_priority_group_elements, :as => :value, :dependent => :destroy
  has_many :events, :as => :source, :dependent => :destroy, :order => 'events.id ASC'

  # Scopes
  scope :enabled, lambda { where(:provider_id => Provider.enabled) }
  has_many :events, :as => :source, :dependent => :destroy,
           :order => 'events.id ASC'
  has_many :provider_images, :class_name => "Tim::ProviderImage"

  # Helpers
  attr_accessor :x509_cert_priv_file, :x509_cert_pub_file
  accepts_nested_attributes_for :credentials
  accepts_nested_attributes_for :quota

  # We set credentials hash as protected so that it is not set during mass assign on new
  # This is to avoid the scenario where the credentials are set before provider which
  # will result in an exception.
  attr_protected :credentials_hash

  # Validations
  validates :label, :presence => true,
                    :uniqueness => true,
                    :length => { :within => 1..100 }
  validates :priority,
            :numericality => { :only_integer => true,
                               :greater_than_or_equal_to => -100,
                               :less_than_or_equal_to => 100 },
            :allow_blank => true
  validates :provider, :presence => true
  validates :quota, :presence => true
  validate :validate_presence_of_credentials
  validate :validate_credentials
  validate :validate_unique_username

  # Callbacks
  before_create :populate_profiles_and_validate
  after_create :populate_realms_and_validate

  def self.additional_privilege_target_types
    [Quota]
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

  def validate_presence_of_credentials
    provider.provider_type.credential_definitions.each do |cd|
      errors.add(:base, "#{I18n.t("provider_accounts.credentials.labels.#{cd.label}")} #{_('can\'t be blank')}") if credentials_hash[cd.name].blank?
    end
  end

  def validate_credentials
    begin
      unless valid_credentials?
        errors.add(:base, _('Login credentials are invalid for this Provider.'))
      end
    rescue
      errors.add(:base, _('An error occurred when checking Provider credentials. Please check your setup and try again.'))
    end
  end

  def validate_unique_username
    username_cred_def = CredentialDefinition.where(:name => 'username', :provider_type_id => provider.provider_type.id).first!
    username_cred = credentials.detect{ |credential| credential.credential_definition_id == username_cred_def.id }
    same_username_creds =
      Credential.where(:credential_definition_id => username_cred_def.id,
                       :value => username_cred.value).
                 where("credentials.id != ?", username_cred.id).all

    if same_username_creds.any?{ |c| c.provider_account.provider_id == username_cred.provider_account.provider_id  }
      username_cred.errors.add(:value, _('Username has already been taken'))
      errors.add(:base, _('Username has already been taken'))
    end
  end

  def perm_ancestors
    super + [provider]
  end

  def check_provider_images!
    imgs = provider_images.map {|pi| pi.target_image.image_version.base_image.name}
    if imgs.empty?
      true
    else
      raise Aeolus::Conductor::Base::NotDestroyable,
        _('There are following associated provider images: %s. Delete them first.') % imgs.join(', ')
    end
  end

  def check_destroyable_instances!
    not_destroyable_instances = instances.find_all {|i| !i.destroyable?}
    if not_destroyable_instances.empty?
      true
    else
      raise Aeolus::Conductor::Base::NotDestroyable,
        _('The following Deployments have not been stopped: %s') % not_destroyable_instances.
            map{|i| i.deployment.nil? ? i.name : i.deployment.name}.uniq.join(', ')
    end
  end

  def remove_pool_family_assoc
    pool_families.clear
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
      client.with_config(opts)
    rescue Exception => ex
      log_backtrace(ex, 'Error connecting to framework')
      nil
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

  def as_json(options={})
    super(options).merge({
      :provider_name => provider.name
    })
  end

  def populate_profiles_and_validate
    begin
      populate_hardware_profiles
    rescue
      errors.add(:base, _('Failed to populate hardware_profiles: %s') % $!.message)
      return false
    end
    true
  end

  def populate_realms_and_validate
    begin
      populate_realms
    rescue
      errors.add(:base, _('Failed to populate Realms: %s') % $!.message)
      raise
    end
    true
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
    label_value_pairs = credentials.map do |c|
      { :label => c.credential_definition.label.downcase.split.join('_'),
        :value => c.value }
    end

    apply_provider_specific_creds!(label_value_pairs)

    # The list is ordered by labels. That way we guarantee that the resulting
    # XML is always the same which makes it easier to verify in tests.
    label_value_pairs.sort { |a, b| a[:label] <=> b[:label] }
  end

  def credentials_hash
    credentials.inject({}) do |hash, cred|
      hash[cred.credential_definition.name] = cred.value
      hash
    end
  end

  def credentials_hash=(hash={})
    if provider
      cred_defs = provider.provider_type.credential_definitions
      hash.each do |k,v|
        cred_def = cred_defs.detect {|d| d.name == k.to_s}
        raise "Key #{k} not found" unless cred_def
        unless cred = credentials.detect{ |c| c.credential_definition_id == cred_def.id }
            cred = Credential.new(:provider_account_id => id, :credential_definition_id => cred_def.id)
            credentials << cred
        end
        # we need to handle uploaded files:
        cred.value = v.respond_to?(:read) ? v.read : v
      end
    end
  end

  def build_credentials
    creds = provider.provider_type.credential_definitions.map do |cd|
      cred = credentials.detect {|c| c.credential_definition_id == cd.id}
      cred ||= Credential.new(:credential_definition => cd, :value => nil)
    end

    self.credentials = creds.sort_by do |cred|
      CredentialDefinition::CREDENTIAL_DEFINITIONS_ORDER.index(cred.credential_definition.name)
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

  def instance_matches(instance, matched, errors)
    if !provider.enabled?
      errors << _('%s: Provider must be enabled') % name
    elsif !provider.available?
      errors << _('%s: Provider is not available') % name
    elsif quota.reached?
      errors << _('%s: Provider Account quota reached') % name
    # match_provider_hardware_profile returns a single provider
    # hardware_profile that can satisfy the input hardware_profile
    elsif !(hwp = HardwareProfile.match_provider_hardware_profile(provider, instance.hardware_profile))
      errors << _('%s: Hardware Profile match not found') % name
    elsif !(account_image = instance.provider_image_for_account(self))
      errors << _('%s: Image is not pushed to this Provider Account') % name
    elsif instance.requires_config_server? and config_server.nil?
      errors << _('%s: no Config Server available for Provider Account') % name
    else
      if not instance.frontend_realm.nil?
        brealms = instance.frontend_realm.realm_backend_targets.select do |brealm_target|
          brealm_target.target_provider == provider &&
            (brealm_target.target_realm.nil? || (brealm_target.target_realm.available &&
                                                 provider_realms.include?(brealm_target.target_realm)))
        end
        if brealms.empty?
          errors << _('%s: Frontend Realm %s is not mapped to an applicable Provider or Provider Realm') % [name, instance.frontend_realm.name]
        else
          brealms.each do |brealm_target|
            # add match if realm is mapped to provider or if it's mapped to
            # backend realm which is available and is accessible for this
            # provider account
            matched << InstanceMatch.new(
              :pool_family => instance.pool.pool_family,
              :provider_account => self,
              :hardware_profile => hwp,
              :provider_image => account_image.external_image_id,
              :provider_realm => brealm_target.target_realm,
              :instance => instance
            )
          end
        end
      else
        matched << InstanceMatch.new(
          :pool_family => instance.pool.pool_family,
          :provider_account => self,
          :hardware_profile => hwp,
          :provider_image => account_image.external_image_id,
          :provider_realm => nil,
          :instance => instance
        )
      end
    end
  end

  def failure_count(options = {})
    relation = self.events.where(:status_code => 'provider_account_failure')

    if options[:from].present?
      relation = relation.where('events.event_time >= :from', :from => options[:from])
    end

    if options[:to].present?
      relation = relation.where('events.event_time <= :to', :to => options[:to])
    end

    relation.count
  end

  def to_polymorphic_path_param(polymorphic_path_extras)
    [provider, self]
  end

  private

  def self.apply_search_filter(search)
    if search
      includes(:provider => [:provider_type]).where("lower(provider_accounts.label) LIKE :search OR lower(providers.name) LIKE :search OR lower(provider_types.name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

  def apply_provider_specific_creds!(label_value_pairs)
    # for openstack we keep username and tenant in username field because of
    # deltacloud, imagefactory expects separate fields,
    # it also requires authentication strategy field
    if provider.provider_type.deltacloud_driver == 'openstack' &&
      userhash = label_value_pairs.find {|i| i[:label] == 'username'}

      username, tenant = userhash[:value].split('+')
      userhash[:value] = username
      label_value_pairs << { :label => 'strategy', :value => 'keystone' }
      label_value_pairs << { :label => 'tenant', :value => tenant }

      # Also add Keystone URL as auth_url for Factory:
      label_value_pairs << { :label => 'auth_url', :value => provider.deltacloud_provider }
    end
  end
end
