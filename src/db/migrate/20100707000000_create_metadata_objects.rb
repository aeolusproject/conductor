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

class CreateMetadataObjects < ActiveRecord::Migration
  def self.up
    create_table :metadata_objects do |t|
      t.string :key, :null => false
      t.string :value, :null => false
      t.string :object_type
      t.integer :lock_version, :default => 0
      t.timestamps
    end

    default_zone = Zone.first
    MetadataObject.set("default_zone", default_zone) if default_zone

    default_pool = Pool.find_by_name("default_pool")

    default_quota = Quota.new
    default_quota.save!

    default_role = Role.find_by_name("Instance Creator and User")
    settings = {"allow_self_service_logins" => "true",
                "self_service_default_quota" => default_quota,
                "self_service_default_pool" => default_pool,
                "self_service_default_role" => default_role}
    settings.each_pair do |key, value|
      MetadataObject.set(key, value)
    end
  end

  def self.down
    drop_table :metadata_objects
  end
end
