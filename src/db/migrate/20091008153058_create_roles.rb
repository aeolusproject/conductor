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

class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string  :name, :null => false
      t.string  :scope, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end
    create_table :privileges_roles, :id => false do |t|
      t.integer :privilege_id, :null => false
      t.integer :role_id,      :null => false
    end

    #create default roles
    roles = {"Instance Controller" =>
                 {:role_scope => "Pool",
                  :privileges => ["instance_control",
                                  "instance_view",
                                  "pool_view"]},
             "Instance Controller With Monitoring" =>
                 {:role_scope => "Pool",
                  :privileges => ["instance_control",
                                  "instance_view",
                                  "pool_view",
                                  "stats_view"]},
             "Instance Creator and User" =>
                 {:role_scope => "Pool",
                  :privileges => ["instance_control",
                                  "instance_view",
                                  "pool_view",
                                  "stats_view",
                                  "instance_modify",
                                  "quota_view",
                                  "set_perms",
                                  "view_perms"]},
             "Self-service Pool User" =>
                 {:role_scope => "Pool",
                  :privileges => ["instance_control",
                                  "instance_view",
                                  "pool_view",
                                  "stats_view",
                                  "instance_modify",
                                  "quota_view",
                                  "set_perms",
                                  "view_perms",
                                  "account_view",
                                  "account_add"]},
             "Pool Creator" =>
                 {:role_scope => "Provider",
                  :privileges => ["provider_view",
                                  "pool_modify",
                                  "pool_view",
                                  "quota_view"]},
             "Pool Administrator" =>
                 {:role_scope => "Provider",
                  :privileges => ["provider_view",
                                  "pool_modify",
                                  "pool_view",
                                  "quota_view",
                                  "quota_modify",
                                  "account_view",
                                  "account_add",
                                  "account_modify",
                                  "set_perms",
                                  "view_perms"]},
             "Provider Administrator" =>
                 {:role_scope => "Provider",
                  :privileges => ["provider_modify",
                                  "provider_view",
                                  "account_modify",
                                  "account_view"]},
             "Account Administrator" =>
                 {:role_scope => "CloudAccount",
                  :privileges => ["set_perms",
                                  "view_perms",
                                  "account_view",
                                  "account_add",
                                  "account_modify"]},
             "Account User" =>
                 {:role_scope => "CloudAccount",
                  :privileges => ["account_view",
                                  "account_add"]},
             "Account Viewer" =>
                 {:role_scope => "CloudAccount",
                  :privileges => ["account_view"]},
             "Provider Creator" =>
                 {:role_scope => "BasePermissionObject",
                  :privileges => ["provider_modify",
                                  "provider_view"]},
             "Administrator" =>
                 {:role_scope => "BasePermissionObject",
                  :privileges => ["provider_modify",
                                  "provider_view",
                                  "account_modify",
                                  "account_add",
                                  "account_view",
                                  "user_modify",
                                  "user_view",
                                  "set_perms",
                                  "view_perms",
                                  "pool_modify",
                                  "pool_view",
                                  "quota_modify",
                                  "quota_view",
                                  "stats_view",
                                  "instance_modify",
                                  "instance_control",
                                  "instance_view"]}

            }
    Role.transaction do
      roles.each do |role_name, role_hash|
        role = Role.new({:name => role_name, :scope => role_hash[:role_scope]})
        role.save!
        role.privileges = role_hash[:privileges].collect do |priv_name|
          Privilege.find_by_name(priv_name)
        end
        role.save!
      end
    end
  end

  def self.down
    drop_table :roles
  end
end
