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
# Table name: hardware_profile_properties
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  kind         :string(255)     not null
#  unit         :string(255)     not null
#  value        :string(255)     not null
#  range_first  :string(255)
#  range_last   :string(255)
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class HardwareProfileProperty < ActiveRecord::Base

  include CostEngine::Mixins::HardwareProfileProperty

  MEMORY       = "memory"
  STORAGE      = "storage"
  CPU          = "cpu"
  ARCHITECTURE = "architecture"

  FIXED = 'fixed'
  RANGE = 'range'
  ENUM  = 'enum'

  UNIT_MB = "MB"
  UNIT_GB = "GB"
  UNIT_LABEL = "label"
  UNIT_COUNT = "count"

  has_many :property_enum_entries

  validates :name, :presence => true,
                   :inclusion => { :in => [MEMORY, STORAGE, CPU, ARCHITECTURE] }
  validates :kind, :presence => true,
                   :inclusion => { :in => [FIXED, RANGE, ENUM] }
  validates :unit, :presence => true
  validates :value, :numericality => { :greater_than => 0, :less_than_or_equal_to => 1048576 },
                    :allow_blank => true,
                    :if => Proc.new{ |p| p.name == MEMORY }
  validates :value, :numericality => { :greater_than => 0, :less_than_or_equal_to => 1024 },
                    :allow_blank => true,
                    :if => Proc.new{ |p| p.name == CPU }
  validates :value, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1048576 },
                    :allow_blank => true,
                    :if => Proc.new{ |p| p.name == STORAGE }
  validates :range_first, :numericality => { :greater_than => 0 },
                          :allow_blank => true,
                          :if => Proc.new{ |p| [MEMORY, STORAGE, CPU].include?(p.name) && p.kind == RANGE }
  validates :range_last, :numericality => { :greater_than => 0 },
                          :allow_blank => true,
                         :if => Proc.new{ |p| [MEMORY, STORAGE, CPU].include?(p.name) && p.kind == RANGE }
  validate :validate_hwp
  validates_associated :property_enum_entries

  def validate_hwp
    case name
    when MEMORY
      unless unit == UNIT_MB
        errors.add(:unit, "Memory must be specified in MB")
      end
    when STORAGE
      unless unit == UNIT_GB
        errors.add(:unit, "Storage must be specified in GB")
      end
    when CPU
      unless unit == UNIT_COUNT
        errors.add(:unit, "CPUs must be specified as a count")
      end
    when ARCHITECTURE
      unless unit == UNIT_LABEL
        errors.add(:unit, "Architecture must be specified as a label")
      end
    end

    if kind==RANGE
      if range_first.nil?
        errors.add(:range_first,
                   "Range beginning must be specified for range properties")
      end
      if range_last.nil?
        errors.add(:range_last,
                   "Range ending must be specified for range properties")
      end
    else
      unless range_first.nil?
        errors.add(:range_first,
                   "Range beginning must only be specified for range properties")
      end
      unless range_last.nil?
        errors.add(:range_last,
                   "Range ending must only be specified for range properties")
      end
    end
  end

  def to_s
    case kind
      when FIXED
        value.to_s
      when RANGE
        range_first.to_s + " - " + range_last.to_s
      when ENUM
        (property_enum_entries.collect { |enum| enum.value }).join(", ")
      else
        "undefined"
    end
  end

  def sort_value(ascending)
    case kind
      when FIXED
         sort_value =  value
      when RANGE
        sort_value = ascending ? range_first : range_last
      when ENUM
        entries = (property_enum_entries.map { |enum| enum.value }).sort!
        sort_value = ascending ? entries.first : entries.last
    end
    return name == "architecture" ? sort_value : sort_value.to_f
  end

  protected

  def is_form_empty?
    # If the form isn't filled out, it comes in as "", which we treat as nil:
    self.value = nil if self.value==""
  end

end

