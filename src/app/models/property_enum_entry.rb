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

class PropertyEnumEntry < ActiveRecord::Base

  belongs_to :hardware_profile_property

  validates_presence_of :value
  validates_presence_of :hardware_profile_property
  validates_numericality_of :value, :greater_than => 0,
                :if => Proc.new{|p| p.hardware_profile_property.name ==
                                    HardwareProfileProperty::MEMORY or
                                 p.hardware_profile_property.name ==
                                     HardwareProfileProperty::STORAGE or
                                 p.hardware_profile_property.name ==
                                   HardwareProfileProperty::CPU }
end
