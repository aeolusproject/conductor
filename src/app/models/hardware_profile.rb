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
class HardwareProfile < ActiveRecord::Base
  searchable do
    text :name, :as => :code_substring
    text(:architecture) { architecture.try :value }
    text(:memory) { memory.try :value }
    text(:storage) { storage.try :value }
    text(:cpu) { cpu.try :value }
    boolean :frontend do
      provider_id.nil?
    end
  end

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
    return nil if prop.nil?
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

  #TODO: This function returns the first hwp in the list of matched hardware profiles
  #      Better logic should be used here to decide which hardware profile to return.
  def self.match_hwp(hwp)
    hwps = matching_hwps(hwp)
    if hwps.empty?
      return nil
    end
    return hwps[0]
  end

  def self.matching_hwps(hwp)
    provider_hwps = HardwareProfile.all(:conditions => 'provider_id IS NOT NULL')
    match_maps = []
    provider_hwps.each do |phwp|
      match_map = check_properties(hwp, phwp)
      if match_map
        match_maps << match_map
      end
    end
    return match_maps
  end

  #TODO: This function returns the first value in hwpp list, better logic is required for for choosing a more appropriate match
  private
  def self.set_non_default_value(hwpp)
    case hwpp.kind
      when 'range'
        hwpp.value = hwpp.range_first
      when 'enum'
        hwpp.value = hwpp.property_enum_entries[0]
      when 'fixed'
        hwpp.value = hwpp.value
    end
    hwpp.save
  end

  def self.check_properties(hwp1, hwp2)
    if [hwp1.memory, hwp1.cpu, hwp1.storage, hwp1.architecture, hwp2.memory, hwp2.cpu, hwp2.storage, hwp2.architecture].include?(nil)
      return nil
    end

    hwpp_mem = check_hwp_property(hwp1.memory, hwp2.memory)
    hwpp_cpu = check_hwp_property(hwp1.cpu, hwp2.cpu)
    hwpp_storage = check_hwp_property(hwp1.storage, hwp2.storage)
    hwpp_arch = check_hwp_property(hwp1.architecture, hwp2.architecture)
    hwpps = [hwpp_mem, hwpp_cpu, hwpp_storage, hwpp_arch]

    if hwpps.include?(nil)
      return nil
    else
      hwpps.each do |hwpp|
        set_non_default_value(hwpp)
      end
      return { :memory => hwpp_mem, :cpu => hwpp_cpu, :storage => hwpp_storage, :architecture => hwpp_arch, :hardware_profile => hwp2}
    end
  end

  def self.check_hwp_property(p1, p2)
    if p1.kind == 'range'
      calculate_range_match(p1, p2)
    elsif p2.kind == 'range'
      calculate_range_match(p2, p1)
    else
      matched_values = (create_array_from_property(p1) & create_array_from_property(p2))
      if !matched_values.empty?
        if p1.kind == 'fixed' || p2.kind == 'fixed'
          HardwareProfileProperty.new(:kind => 'fixed', :value => matched_values[0])
        else
          hwpp = HardwareProfileProperty.new(:kind => 'enum')
          matched_values.each do |enum_value|
            hwpp.property_enum_entries << PropertyEnumEntry.new(:hardware_profile_property => hwpp, :value => enum_value)
          end
          return hwpp
        end
      else
        return nil
      end
    end
  end

  def self.calculate_range_match(p1, p2)
    case p2.kind
    when 'range'
      if !(BigDecimal.new(p1.range_first) > BigDecimal.new(p2.range_last) || BigDecimal.new(p1.range_last) < BigDecimal.new(p2.range_first))
        hwpp = HardwareProfileProperty.new(:kind => 'range')

        hwpp.range_first = BigDecimal.new(p1.range_first) >= BigDecimal.new(p2.range_first) ? p1.range_first : p2.range_first
        hwpp.range_last = BigDecimal.new(p1.range_last) <= BigDecimal.new(p2.range_last) ? p1.range_last : p2.range_last

        return hwpp
      else
        return nil
      end

    when 'enum'
      hwpp = HardwareProfileProperty.new(:kind => 'enum')
      p2.property_enum_entries.each do |enum|
        if (BigDecimal.new(p1.range_first)..BigDecimal.new(p1.range_last)) === BigDecimal.new(enum.value)
          hwpp.property_enum_entries << PropertyEnumEntry.new(:hardware_profile_property => hwpp, :value => enum.value)
        end
      end
      return hwpp.property_enum_entries.empty? ? nil : hwpp

    when 'fixed'
      return (BigDecimal.new(p1.range_first)..BigDecimal.new(p1.range_last)) === BigDecimal.new(p2.value) ? HardwareProfileProperty.new(:kind => 'fixed', :value => p2.value) : nil

    else
      return nil

    end
  end

  def self.create_array_from_property(p)
    case p.kind
    when 'fixed'
      return [p.value]

    when 'enum'
      return p.property_enum_entries.map { |enum| enum.value }
    end
  end

end
