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

class HardwareProfile < ActiveRecord::Base
  has_many :instances
  has_many :provider_instances, :class_name => "Instance",
           :foreign_key => "provider_hardware_profile_id"
  belongs_to :provider
  belongs_to :pool

  has_and_belongs_to_many :aggregator_hardware_profiles,
                          :class_name => "HardwareProfile",
                          :join_table => "hardware_profile_map",
                          :foreign_key => "provider_hardware_profile_id",
                          :association_foreign_key => "aggregator_hardware_profile_id"

  has_and_belongs_to_many :provider_hardware_profiles,
                          :class_name => "HardwareProfile",
                          :join_table => "hardware_profile_map",
                          :foreign_key => "aggregator_hardware_profile_id",
                          :association_foreign_key => "provider_hardware_profile_id"

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :scope => [:provider_id, :pool_id]

  validates_presence_of :name

  validates_presence_of :storage
  validates_numericality_of :storage
  validates_presence_of :memory
  validates_numericality_of :memory

  validates_presence_of :architecture, :if => :provider

  def validate
    if (provider.nil? and pool.nil?)
      if !aggregator_hardware_profiles.empty?
        errors.add(:aggregator_hardware_profiles,
                   "Aggregator profiles are not allowed for custom Instance profiles")
      end
      if !provider_hardware_profiles.empty?
        errors.add(:provider_hardware_profiles,
                   "Provider profiles are not allowed for custom Instance profiles")
      end
    elsif (!provider.nil? and !pool.nil?)
      errors.add(:provider, "provider or pool must be blank")
      errors.add(:pool, "provider or pool must be blank")
    elsif provider.nil?
      if !provider_hardware_profiles.empty?
        errors.add(:provider_hardware_profiles,
                   "Provider profiles only allowed for provider profiles")
      end
    elsif pool.nil?
      if !aggregator_hardware_profiles.empty?
        errors.add(:aggregator_hardware_profiles,
                   "Aggregator profiles only allowed for pool profiles")
      end
    end
  end
end
