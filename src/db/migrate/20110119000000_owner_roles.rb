#
# Copyright (C) 2011 Red Hat, Inc.
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

class OwnerRoles < ActiveRecord::Migration

  OWNER_ROLES = ["Instance Owner",
                 "Pool Family Owner",
                 "Pool Owner",
                 "Provider Owner",
                 "Provider Account Owner",
                 "LegacyTemplate Owner"]

  def self.up
    add_column :roles, :assign_to_owner, :boolean, :default => false

    Role.transaction do
      OWNER_ROLES.each do |role_name|
        role = Role.find_by_name(role_name)
        unless role.nil?
          role.assign_to_owner = true
          role.save!
        end
      end
    end
  end

  def self.down
    remove_column :roles, :assign_to_owner
  end
end
