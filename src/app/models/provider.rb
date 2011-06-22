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

require 'sunspot_rails'
class Provider < ActiveRecord::Base
  searchable do
    text :name, :as => :code_substring
    text :url, :as => :code_substring
  end

  require 'util/conductor'
  include PermissionedObject

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


  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  before_destroy :destroyable?

  # there is a destroy dependency for a cloud accounts association,
  # but a cloud account is silently not destroyed when there is
  # an instance for the cloud account
  def destroyable?
    unless self.provider_accounts.empty?
      self.provider_accounts.each do |c|
        unless c.instances.empty?
          inst_list = c.instances.map {|i| i.name}.join(', ')
          self.errors.add_to_base "there are instances for cloud account '#{c.name}': #{inst_list}"
        end
      end
    end
    return self.errors.empty?
  end

  def connect
    begin
      return DeltaCloud.new(nil, nil, url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def populate_hardware_profiles
    # FIXME: once API has hw profiles, change the below
    hardware_profiles = connect.hardware_profiles
    # FIXME: this should probably be in the same transaction as provider.save
    self.transaction do
      hardware_profiles.each do |hardware_profile|
        ar_hardware_profile = HardwareProfile.new(:external_key =>
                                                  hardware_profile.id,
                                                  :name => hardware_profile.id,
                                                  :provider_id => id)
        ar_hardware_profile.add_properties(hardware_profile)
        ar_hardware_profile.save!
      end
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
  def validate
    if !nil_or_empty(url)
      errors.add("url", "must be a valid provider url") unless valid_framework?
    end
  end

  private

  def valid_framework?
    connect.nil? ? false : true
  end

end
