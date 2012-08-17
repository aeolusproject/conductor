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
# Table name: property_enum_entries
#
#  id                           :integer         not null, primary key
#  hardware_profile_property_id :integer         not null
#  value                        :string(255)     not null
#  lock_version                 :integer         default(0)
#  created_at                   :datetime
#  updated_at                   :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class PropertyEnumEntry < ActiveRecord::Base

  belongs_to :hardware_profile_property

  validates_presence_of :value
  validates_presence_of :hardware_profile_property
  validates_numericality_of :value, :greater_than => 0,
    :if => Proc.new { |p|
            p.hardware_profile_property.name == HardwareProfileProperty::MEMORY or
            p.hardware_profile_property.name == HardwareProfileProperty::STORAGE or
            p.hardware_profile_property.name == HardwareProfileProperty::CPU
          }

  def to_s
    value.to_s + ", "
  end

end
