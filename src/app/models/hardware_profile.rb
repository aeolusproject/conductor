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
  named_scope :frontend, :conditions => { :provider_id => nil }
  has_many :provider_instances, :class_name => "Instance",
           :foreign_key => "provider_hardware_profile_id"

  belongs_to :provider

  belongs_to :memory,       :class_name => "HardwareProfileProperty",
                            :dependent => :destroy
  belongs_to :storage,      :class_name => "HardwareProfileProperty",
                            :dependent => :destroy
  belongs_to :cpu,          :class_name => "HardwareProfileProperty",
                            :dependent => :destroy
  belongs_to :architecture, :class_name => "HardwareProfileProperty",
                            :dependent => :destroy

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
  validates_uniqueness_of :external_key, :scope => [:provider_id]

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:provider_id]

  validates_associated :memory
  validates_associated :storage
  validates_associated :cpu
  validates_associated :architecture

  def provider_hardware_profile?
    !provider.nil?
  end

  # FIXME: what about custom instance profiles?
  def validate
    if provider.nil?
      if !aggregator_hardware_profiles.empty?
        errors.add(:aggregator_hardware_profiles,
                   "Aggregator profiles only allowed for provider profiles")
      end
    else
      if !provider_hardware_profiles.empty?
        errors.add(:provider_hardware_profiles,
                   "Provider profiles only allowed for aggregator profiles")
      end
    end
  end

  def add_properties(api_profile)
    self.memory = new_property(api_profile.memory)
    self.storage = new_property(api_profile.storage)
    self.cpu = new_property(api_profile.cpu)
    self.architecture = new_property(api_profile.architecture)
  end
  def new_property(prop)
    return nil unless prop.present?
    the_property = HardwareProfileProperty.new(:name  => prop.name,
                                               :kind  => prop.kind.to_s,
                                               :unit  => prop.unit,
                                               :value => prop.value)
    case prop.kind.to_s
    when HardwareProfileProperty::RANGE
      the_property.range_first = prop.range[:from]
      the_property.range_last = prop.range[:to]
    when HardwareProfileProperty::ENUM
      the_property.property_enum_entries = prop.options.collect do |entry|
        PropertyEnumEntry.new(:value => entry, :hardware_profile_property => the_property)
      end
    end
    the_property
  end
end
