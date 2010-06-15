#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.string  :name, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    #create default privileges
    privileges = ["set_perms", "view_perms",
                  "instance_modify", "instance_control", "instance_view",
                  "stats_view",
                  "account_modify", "account_view",
                  "pool_modify", "pool_view",
                  "quota_modify", "quota_view",
                  "provider_modify", "provider_view",
                  "user_modify", "user_view",
                  "image_modify", "image_view"]
    Privilege.transaction do
      privileges.each do |priv_name|
        privilege = Privilege.new({:name => priv_name})
        privilege.save!
      end
    end
  end

  def self.down
    drop_table :privileges
  end
end
