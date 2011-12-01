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
