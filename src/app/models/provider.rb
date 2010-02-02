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
  require 'util/deltacloud'

  has_many :cloud_accounts,  :dependent => :destroy
  has_many :hardware_profiles,  :dependent => :destroy
  has_many :images,  :dependent => :destroy
  has_many :realms,  :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :cloud_type
  validates_presence_of :url

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

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
    hardware_profiles = connect.hardware_profiles
    # FIXME: this should probably be in the same transaction as provider.save
    self.transaction do
      hardware_profiles.each do |hardware_profile|
        ar_hardware_profile = HardwareProfile.new(:external_key => hardware_profile.id,
                               :name => hardware_profile.name ? hardware_profile.name : hardware_profile.id,
                               :memory => hardware_profile.memory,
                               :storage => hardware_profile.storage,
                               :architecture => hardware_profile.architecture,
                               :provider_id => id)
        ar_hardware_profile.save!
      end
    end
  end

  # TODO: implement or remove - this is meant to contain a hash of
  # supported cloud_types to use in populating form, though if we
  # infer that field, we don't need this.
  def supported_types
  end

  protected
  def validate
    if !nil_or_empty(url)
      errors.add("url", "must be a valid provider url") unless valid_framework?
      puts errors.inspect
    end
  end

  private

  def valid_framework?
    connect.nil? ? false : true
  end
end
