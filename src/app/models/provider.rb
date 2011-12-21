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

  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"
  validates_length_of :name,  :maximum => 255
  validate :validate_provider

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  before_destroy :destroyable?

  scope :enabled, where("enabled = ?", true)

  def encoded_url_with_driver_and_provider
    url_extras = ";driver=#{provider_type.deltacloud_driver}"
    if deltacloud_provider
      url_extras += ";provider=#{CGI::escape(deltacloud_provider)}"
    end
    return url + url_extras
  end
  # there is a destroy dependency for a cloud accounts association,
  # but a cloud account is silently not destroyed when there is
  # an instance for the cloud account
  def destroyable?
    unless self.provider_accounts.empty?
      self.provider_accounts.each do |c|
        unless c.instances.empty?
          inst_list = c.instances.map {|i| i.name}.join(', ')
          self.errors.add(:base, "there are instances for cloud account '#{c.name}': #{inst_list}")
        end
      end
    end
    return self.errors.empty?
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

  # returns all frontend realms which are associated with this provider or a
  # realm of this provider
  def all_associated_frontend_realms
    (frontend_realms + realms.map {|r| r.frontend_realms}.flatten).uniq
  end

  def stop_instances(user)
    errs = []
    provider_accounts.each do |pa|
      pa.instances.stopable.each do |instance|
        begin
          unless instance.valid_action?('stop')
            raise "stop is an invalid action."
          end

          unless @task = instance.queue_action(user, 'stop')
            raise "stop cannot be performed on this instance."
          end
          Taskomatic.stop_instance(@task)
        rescue Exception => e
          err = "Error while stopping an instance #{instance.name}: #{e.message}"
          errs << err
          logger.error err
          logger.error e.backtrace.join("\n  ")
        end
      end
    end
    errs
  end

  protected
  def validate_provider
    if !nil_or_empty(url)
      errors.add("url", "must be a valid provider url") unless valid_framework?
    end
  end

  private

  def valid_framework?
    connect.nil? ? false : true
  end

end
