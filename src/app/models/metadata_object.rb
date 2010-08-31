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

class MetadataObject < ActiveRecord::Base

  validates_presence_of :key
  validates_uniqueness_of :key

  validates_presence_of :value

  def self.lookup(key)
    metadata_obj = self.find_by_key(key)
    if metadata_obj.nil?
      nil
    elsif metadata_obj.object_type and !metadata_obj.object_type.empty?
      metadata_obj.object_type.constantize.find(metadata_obj.value)
    else
      metadata_obj.value
    end
  end

  def self.set(key, value)
    metadata_obj = self.find_by_key(key)
    metadata_obj = self.new(:key => key) unless metadata_obj

    if value.is_a?(ActiveRecord::Base)
      metadata_obj.object_type = value.class.to_s
      metadata_obj.value = value.id
    else
      metadata_obj.value = value
      metadata_obj.object_type = nil
    end
    metadata_obj.save!
    metadata_obj
  end

  def self.remove(key)
    metadata_obj = self.find_by_key(key)
    metadata_obj.destroy if metadata_obj
  end

end
