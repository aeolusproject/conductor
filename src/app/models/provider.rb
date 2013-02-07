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
# Schema version: 20110223132404
#
# Table name: providers
#
#  id               :integer         not null, primary key
#  name             :string(255)     not null
#  url              :string(255)     not null
#  lock_version     :integer         default(0)
#  created_at       :datetime
#  updated_at       :datetime
#  provider_type_id :integer         default(100), not null
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Provider < ActiveRecord::Base

  include PermissionedObject

  DEFAULT_DELTACLOUD_URL = SETTINGS_CONFIG[:default_deltacloud_url]

  has_many :provider_accounts, :dependent => :destroy
  has_many :hardware_profiles, :dependent => :destroy
  has_many :provider_realms, :dependent => :destroy
  has_many :realm_backend_targets, :as => :provider_realm_or_provider, :dependent => :destroy
  has_many :frontend_realms, :through => :realm_backend_targets
  belongs_to :provider_type
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"
  has_many :provider_priority_group_elements, :as => :value, :dependent => :destroy
  has_many :provider_priority_groups, :through => :provider_priority_group_elements

  scope :enabled, where("enabled = ?", true)

  validates :name, :presence => true,
                   :uniqueness => true,
                   :format => {:with => /^[\w -]*$/n},
                   :length => { :within => 1..100 }
  validates :url, :presence => true,
                  :length => { :within => 1..100 }
  validates :provider_type_id, :presence => true
  validate :validate_provider

  before_save :check_name

  def self.additional_privilege_target_types
    [ProviderAccount]
  end

  def check_name
    case provider_type.name
      when "Mock"
        if name.starts_with?("mock")
          true
        else
          errors.add(:name, :start_with_mock)
          false
        end
      when "RHEV-M"
        load_json.present?
      when "VMware vSphere"
        load_json.present?
    end
  end

  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += provider_accounts if (role.nil? or role.privilege_target_match(ProviderAccount))
    subtree
  end


  def encoded_url_with_driver_and_provider
    url_extras = ";driver=#{provider_type.deltacloud_driver}"
    if deltacloud_provider
      url_extras += ";provider=#{CGI::escape(deltacloud_provider)}"
    end
    return url + url_extras
  end

  def connect
    begin
      connect!
    rescue Exception => ex
      log_backtrace(ex, 'Error connecting to framework')
      nil
    end
  end

  def connect!
    opts = {:username => nil,
            :password => nil,
            :driver => provider_type.deltacloud_driver }
    opts[:provider] = deltacloud_provider if deltacloud_provider
    client = DeltaCloud.new(nil, nil, url)
    client.with_config(opts)
  end

  def pools
    cloud_accounts.collect {|account| account.pools}.flatten.uniq
  end

  def disable(user)
    res = {}
    if valid_framework?
      # if we can connect to the provider, try to stop running instances
      # TODO: now provider is disabled even if stop request fails, is it ok?
      res[:failed_to_stop] = stop_instances(user)
    else
      # if the provider is not accessible and there are no running
      # instances, we just change state of all instances to stopped
      res[:failed_to_terminate] = instances_to_terminate.select do |i|
        begin
          i.update_attributes(:state => Instance::STATE_STOPPED)
          false
        rescue
          true
          # this should never happen, so display an error only in log file
          log_backtrace($!, "Failed to stop instance #{i.name}")
        end
      end
    end
    if res[:failed_to_stop].blank? and res[:failed_to_terminate].blank?
      Provider.skip_callback :save, :check_name
      update_attribute(:enabled, false)
    end
    res
  end

  def instances_to_terminate
    return [] if valid_framework?
    provider_accounts.inject([]) {|all, pa| all += pa.instances.stoppable_inaccessible}
  end

  def update_availability
    self.available = valid_framework?
    if self.available_changed? and !new_record?
      update_attribute(:available, self.available)
      logger.warn "#{name} provider's availability changed to #{self.available}"
    end
    self.available
  end

  def populate_realms
    reload

    # if the provider is not running, mark as unavailable and don't refresh its
    # realms
    return unless update_availability

    conductor_acct_realms = {}
    conductor_acct_realm_ids = {}
    deltacloud_realms = []
    dc_acct_realms = {}
    dc_acct_realm_ids = {}
    self.transaction do
      provider_accounts.each do |acct|
        # if account is not accessible (but provider is running)
        # account's realms will be removed
        unless client = acct.connect
          logger.warn "provider account #{acct.name} is not available"
          next
        end
        dc_acct_realms[acct.label] = client.realms
        dc_acct_realm_ids[acct.label] = dc_acct_realms[acct.label].collect{|r| r.id}
        dc_acct_realms[acct.label].each do |dc_realm|
          if deltacloud_realms.select {|r| r.id == dc_realm.id }.empty?
            deltacloud_realms << dc_realm
          end
        end
        conductor_acct_realms[acct.label] = acct.provider_realms
        conductor_acct_realm_ids[acct.label] = conductor_acct_realms[acct.label].collect{|r| r.external_key}

        # Remove any provider account mappings in Conductor that aren't in Deltacloud
        conductor_acct_realms[acct.label].each do |c_realm|
          unless dc_acct_realm_ids[acct.label].include?(c_realm.external_key)
            acct.provider_realms.delete(c_realm)
          end
        end
      end
      deltacloud_realm_ids = deltacloud_realms.collect{|r| r.id}
      # Delete anything in Conductor that's not in Deltacloud
      conductor_realms = provider_realms
      conductor_realm_ids = conductor_realms.collect{|r| r.external_key}
      conductor_realms.each do |c_realm|
        unless deltacloud_realm_ids.include?(c_realm.external_key)
          #c_realm.reload
          c_realm.destroy
        end
      end

      # Add anything in Deltacloud to Conductor if it's not already there
      deltacloud_realms.each do |d_realm|
        unless ar_realm = conductor_realms.detect {|r| r.external_key == d_realm.id}
          ar_realm = ProviderRealm.new(:external_key => d_realm.id,
                                 :name => d_realm.name ? d_realm.name : d_realm.id,
                                 :provider_id => id)
        end
        ar_realm.available = d_realm.state.downcase == 'available'
        ar_realm.save!
      end

      # add any new provider account realm mappings
      provider_accounts.each do |acct|
        next unless dc_acct_realms[acct.label]
        dc_acct_realms[acct.label].each do |d_realm|
          unless conductor_acct_realm_ids[acct.label].include?(d_realm.id)
            acct.provider_realms << provider_realms.where("external_key" => d_realm.id)
          end
        end
      end
    end

  end

  def imagefactory_info
    if provider_type.deltacloud_driver == 'openstack'
      # TODO: We might want to pull this up to the Provider, really
      acct = provider_accounts.first
      uri = URI.parse(acct.credentials_hash['glance_url'])
      {
        'glance-host' => uri.host,
        'glance-port' => uri.port,
      }
    elsif ['rhevm', 'vsphere'].include?(provider_type.deltacloud_driver)
      if json = load_json
        json
      else
        raise _('Config for %s was not found.') % self.name
      end
    elsif provider_type.deltacloud_driver == 'ec2'
      {'name' => deltacloud_provider}
    else
      {}
    end
  end

  protected

  def stop_instances(user)
    errs = []
    stoppable_instances.each do |instance|
      begin
        instance.stop(user)
      rescue Exception => ex
        log_backtrace(ex, text="Error while stopping an instance #{instance.name}")
        errs << "#{text}: #{ex.message}"
      end
    end
    errs
  end

  def stoppable_instances
    provider_accounts.inject([]) {|all, pa| all += pa.instances.stoppable}
  end

  def validate_provider
    if provider_type
      if !nil_or_empty(url)
        errors.add('url', :invalid_framework) unless valid_framework?
        #errors.add('deltacloud_provider', :invalid_provider) unless valid_provider?
      end
    else
      errors.add('provider_type', :'does_not_exist')
    end
  end

  private

  def valid_framework?
    begin
      !! connect!
    rescue DeltaCloud::HTTPError::Unauthorized
      # Some providers will return a 401 - Unauthorized, which is okay at
      # this stage (since we haven't passed in credentials yet):
      return true
    rescue Exception => ex
      log_backtrace(ex, "Error connecting to framework")
      return false
    end
  end

  def valid_provider?
    if !nil_or_empty(deltacloud_provider)
      client = connect
      return false if client.nil?
      return false unless client.driver(provider_type.deltacloud_driver).valid_provider? deltacloud_provider
    end
    true
  end

  def load_json
    path_to_json = "/etc/imagefactory/#{provider_type.deltacloud_driver}.json"
    if File.exists?(path_to_json)
      json = File.read(path_to_json)
      json_hash = ActiveSupport::JSON.decode(json)
      if json_hash.key?(name)
        json_hash[name]
      else
        errors.add(:name, :not_found_in_config)
        nil
      end
    else
      errors.add(:name, :config_not_exist)
      nil
    end
  end
end
