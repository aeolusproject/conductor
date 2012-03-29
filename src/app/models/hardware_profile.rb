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
# Schema version: 20110207110131
#
# Table name: hardware_profiles
#
#  id              :integer         not null, primary key
#  external_key    :string(255)
#  name            :string(1024)    not null
#  memory_id       :integer
#  storage_id      :integer
#  cpu_id          :integer
#  architecture_id :integer
#  provider_id     :integer
#  lock_version    :integer         default(0)
#  created_at      :datetime
#  updated_at      :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class HardwareProfile < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  include PermissionedObject
  has_many :permissions, :as => :permission_object, :dependent => :destroy
  has_many :instances
  scope :frontend, :conditions => { :provider_id => nil }
  has_many :provider_instances, :class_name => "Instance",
           :foreign_key => "provider_hardware_profile_id"

  belongs_to :provider

  belongs_to :memory,       :class_name => "HardwareProfileProperty",
                            :dependent => :destroy,
                            :validate => false

  belongs_to :storage,      :class_name => "HardwareProfileProperty",
                            :dependent => :destroy,
                            :validate => false

  belongs_to :cpu,          :class_name => "HardwareProfileProperty",
                            :dependent => :destroy,
                            :validate => false

  belongs_to :architecture, :class_name => "HardwareProfileProperty",
                            :dependent => :destroy,
                            :validate => false

  accepts_nested_attributes_for :memory, :cpu, :storage, :architecture

  validates_presence_of :external_key, :if => Proc.new { |hwp| !hwp.provider.nil? }
  validates_uniqueness_of :external_key, :scope => [:provider_id], :if => Proc.new { |hwp| !hwp.provider.nil? }

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:provider_id]


  validates_associated :memory
  validates_associated :storage
  validates_associated :cpu
  validates_associated :architecture

  def get_property_map
    return {'memory' => memory, 'cpu' => cpu, 'architecture' => architecture, 'storage' => storage}
  end

  def provider_hardware_profile?
    !provider.nil?
  end

  def add_properties(api_profile)
    self.memory = property_from_api_or_default(api_profile, :memory)
    self.storage = property_from_api_or_default(api_profile, :storage)
    self.cpu = property_from_api_or_default(api_profile, :cpu)
    self.architecture = property_from_api_or_default(api_profile, :architecture)
  end

  def property_from_api_or_default(api_profile, attribute)
    prop = nil
    begin
      prop = api_profile.send(attribute)
    rescue NoMethodError
    end
    new_property(prop || default_profile(attribute))
  end

  # If there is no property (nil on the API), create a default
  def default_profile(type)
    return nil unless [:memory, :storage, :cpu, :architecture].include?(type)
    HardwareProfileProperty.new(
        :name => type.to_s,
        :kind => :fixed,
        :unit => {:memory => 'MB', :cpu => 'count', :storage => 'GB', :architecture => 'label'}[type],
        :value => nil
    )
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

  def self.matching_hardware_profiles(hardware_profile)
    hardware_profiles = Provider.find(:all).map { |provider| match_provider_hardware_profile(provider, hardware_profile)}
    hardware_profiles.select {|hwp| hwp != nil }
  end

  def self.match_provider_hardware_profile(provider, hardware_profile)
    hardware_profiles = match_hardware_profiles(provider, hardware_profile)
    # there can be multiple matching hw profiles,
    # for now pick hw profile with lowest memory.
    # (supposing that memory is most expensive component
    # of hw profile)
    hardware_profiles.sort do |hw1, hw2|
      BigDecimal.new(hw1.memory.sort_value(false).to_s) <=> BigDecimal.new(hw2.memory.sort_value(false).to_s)
    end.first
  end

  def self.generate_override_property_values(front_end_hwp, back_end_hwp)
    property_overrides = {}
    property_overrides[:memory] = generate_override_property_value(front_end_hwp.memory, back_end_hwp.memory)
    property_overrides[:storage] = generate_override_property_value(front_end_hwp.storage, back_end_hwp.storage)
    property_overrides[:cpu] = generate_override_property_value(front_end_hwp.cpu, back_end_hwp.cpu)
    property_overrides[:architecture] = front_end_hwp.architecture.value
    return property_overrides
  end

  PRESET_FILTERS_OPTIONS =
    [
    #{:title => "hardware_profiles.preset_filters.i386architecture", :id => "i386architecture", :query => includes(:architecture).where('architecture.value' => "i386")},
    #{:title => "hardware_profiles.preset_filters.x86_64architecture", :id => "x86_64architecture", :query => includes(:architecture).where('architecture.value' => "x86_64")}
    ]

  private

  def self.apply_search_filter(search)
    if search
      where("lower(name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

  def self.generate_override_property_value(front_end_property, back_end_property)
    case back_end_property.kind
      when "fixed"
        return back_end_property.value
      when "range"
        return back_end_property.value.to_i unless front_end_property.value.present?
        val = front_end_property.value.to_i
        if val < back_end_property.range_first.to_i
          return back_end_property.range_first.to_i
        elsif val > back_end_property.range_last.to_i
          return back_end_property.range_last.to_i
        else
          return val
        end
      when "enum"
        create_array_from_property(back_end_property).sort!.each do |value|
          if front_end_property.value.nil? or BigDecimal.new(value) >= BigDecimal.new(front_end_property.value)
            return value
          end
        end
    end
    return nil
  end

  def self.match_hardware_profiles(provider, hardware_profile)
    back_end_profiles = provider.hardware_profiles
    back_end_profiles.select { |hwp| match_hardware_profile(hardware_profile, hwp)}
  end

  def self.match_hardware_profile(front_end_hwp, back_end_hwp)
    # short-term hack to deal with the fact that t1.micro HWP is
    # ebs-only, but we don't support ebs yet. Longer-term we'll need
    # to handle this case explicitly
    if back_end_hwp.name == "t1.micro"
      return false
    end
    if back_end_hwp.name == "opaque"
      return false
    end
    match_hardware_profile_property(front_end_hwp.memory, back_end_hwp.memory) &&
    match_hardware_profile_property(front_end_hwp.cpu, back_end_hwp.cpu) &&
    match_hardware_profile_property(front_end_hwp.storage, back_end_hwp.storage) &&
    match_hardware_profile_property(front_end_hwp.architecture, back_end_hwp.architecture)
  end

  def self.match_hardware_profile_property(front_end_property, back_end_property)
    # if the front_end_property is nil, we don't care about it, so everything matches:
    return true if front_end_property.nil? || front_end_property.value.to_s.empty?
    # if the back_end_property is nil, it only matches if front-end is also nil:
    return false if back_end_property.nil? || back_end_property.value.to_s.empty?
    # Otherwise, neither are nil, so compare normally:
    match = false
    case back_end_property.kind
      when "fixed"
        if !is_numeric(front_end_property.value.to_s) || !is_numeric(back_end_property.value.to_s)
          if front_end_property.value.to_s == back_end_property.value.to_s
            match = true
          end
        else
          match = BigDecimal.new(back_end_property.value.to_s) >= BigDecimal.new(front_end_property.value.to_s) ? true : false
        end
      when "range"
        match = BigDecimal.new(back_end_property.range_last.to_s) >= BigDecimal.new(front_end_property.value.to_s) ? true : false
      when "enum"
        create_array_from_property(back_end_property).each do |value|
        if front_end_property.value.nil?
          match = true
        elsif !is_numeric(front_end_property.value.to_s) || !is_numeric(value.to_s)
          if front_end_property.value.to_s == value.to_s
            match = true
          end
        elsif BigDecimal.new(value) >= BigDecimal.new(front_end_property.value.to_s)
          match = true
        end
      end
    end
    return match
  end

  def self.create_array_from_property(p)
    case p.kind
    when 'fixed'
      return [p.value]

    when 'enum'
      return p.property_enum_entries.map { |enum| enum.value }
    end
  end

  def self.is_numeric(value)
    true if Float(value) rescue false
  end

end
