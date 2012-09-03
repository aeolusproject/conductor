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
  require 'util/conductor'
  include PermissionedObject

  DEFAULT_DELTACLOUD_URL = SETTINGS_CONFIG[:default_deltacloud_url]

  has_many :provider_accounts, :dependent => :destroy
  has_many :hardware_profiles, :dependent => :destroy
  has_many :realms, :dependent => :destroy
  has_many :realm_backend_targets, :as => :realm_or_provider, :dependent => :destroy
  has_many :frontend_realms, :through => :realm_backend_targets
  belongs_to :provider_type

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :provider_type_id
  validates_presence_of :url

  validates_format_of :name, :with => /^[\w -]*$/n
  validates_length_of :name,  :maximum => 255
  validate :validate_provider

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"
  has_many :provider_priority_group_elements, :as => :value, :dependent => :destroy
  has_many :provider_priority_groups, :through => :provider_priority_group_elements

  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += provider_accounts if (role.nil? or role.privilege_target_match(ProviderAccount))
    subtree
  end
  def self.additional_privilege_target_types
    [ProviderAccount]
  end

  scope :enabled, where("enabled = ?", true)

  def encoded_url_with_driver_and_provider
    url_extras = ";driver=#{provider_type.deltacloud_driver}"
    if deltacloud_provider
      url_extras += ";provider=#{CGI::escape(deltacloud_provider)}"
    end
    return url + url_extras
  end

  def connect
    begin
      opts = {:username => nil,
              :password => nil,
              :driver => provider_type.deltacloud_driver }
      opts[:provider] = deltacloud_provider if deltacloud_provider
      client = DeltaCloud.new(nil, nil, url)
      return client.with_config(opts)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def pools
    cloud_accounts.collect {|account| account.pools}.flatten.uniq
  end

  # TODO: implement or remove - this is meant to contain a hash of
  # supported provider_types to use in populating form, though if we
  # infer that field, we don't need this.
  def supported_types
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
          logger.warn "failed to stop instance #{i.name}: #{$!.message}"
          logger.warn $!.backtrace.join("\n ")
        end
      end
    end
    if res[:failed_to_stop].blank? and res[:failed_to_terminate].blank?
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
        conductor_acct_realms[acct.label] = acct.realms
        conductor_acct_realm_ids[acct.label] = conductor_acct_realms[acct.label].collect{|r| r.external_key}

        # Remove any provider account mappings in Conductor that aren't in Deltacloud
        conductor_acct_realms[acct.label].each do |c_realm|
          unless dc_acct_realm_ids[acct.label].include?(c_realm.external_key)
            acct.realms.delete(c_realm)
          end
        end
      end
      deltacloud_realm_ids = deltacloud_realms.collect{|r| r.id}
      # Delete anything in Conductor that's not in Deltacloud
      conductor_realms = realms
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
          ar_realm = Realm.new(:external_key => d_realm.id,
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
            acct.realms << realms.where("external_key" => d_realm.id)
          end
        end
      end
    end

  end

  protected

  def stop_instances(user)
    errs = []
    stoppable_instances.each do |instance|
      begin
        instance.stop(user)
      rescue Exception => e
        err = "Error while stopping an instance #{instance.name}: #{e.message}"
        errs << err
        logger.error err
        logger.error e.backtrace.join("\n  ")
      end
    end
    errs
  end

  def stoppable_instances
    provider_accounts.inject([]) {|all, pa| all += pa.instances.stoppable}
  end

  def validate_provider
    if !nil_or_empty(url)
      errors.add('url', :invalid_framework) unless valid_framework?
      #errors.add('deltacloud_provider', :invalid_provider) unless valid_provider?
    end
  end

  private

  def valid_framework?
    connect.nil? ? false : true
  end

  def valid_provider?
    if !nil_or_empty(deltacloud_provider)
      client = connect
      return false if client.nil?
      return false unless client.driver(provider_type.deltacloud_driver).valid_provider? deltacloud_provider
    end
    true
  end
end
