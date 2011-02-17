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

#
# Copyright (C) 2010 Red Hat, Inc.
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

class HardwareProfileProperty < ActiveRecord::Base

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

  validates_presence_of :name
  validates_inclusion_of :name,
     :in => [MEMORY, STORAGE, CPU, ARCHITECTURE]

  validates_presence_of :kind
  validates_inclusion_of :kind,
     :in => [FIXED, RANGE, ENUM]

  validates_presence_of :unit
  validates_presence_of :value
  validates_numericality_of :value, :greater_than => 0,
                :if => Proc.new{|p| p.name == MEMORY or p.name == STORAGE or p.name == CPU}

  validates_numericality_of :range_first, :greater_than => 0,
                :if => Proc.new{|p| (p.name == MEMORY or p.name == STORAGE or p.name == CPU) and
                                     p.kind == RANGE}
  validates_numericality_of :range_last, :greater_than => 0,
                :if => Proc.new{|p| (p.name == MEMORY or p.name == STORAGE or p.name == CPU) and
                                     p.kind == RANGE}
  validates_associated :property_enum_entries
  def validate
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
end

