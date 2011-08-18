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

class Provider < ActiveRecord::Base
  require 'util/conductor'
  include PermissionedObject

  # once we're using settings.yml for other things we should move this
  # to a more general location
  SETTINGS_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")
  DEFAULT_DELTACLOUD_URL = SETTINGS_CONFIG['default_deltacloud_url']

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
