#
#   Copyright 2012 Red Hat, Inc.
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

class ChangePermissionUser < ActiveRecord::Migration
  class Permission < ActiveRecord::Base; end
  class DerivedPermission < ActiveRecord::Base; end

  def self.up
    add_column :permissions, :entity_id, :integer
    add_column :derived_permissions, :entity_id, :integer

    Permission.reset_column_information
    DerivedPermission.reset_column_information

    counter = 0
    total_perms = Permission.count
    Permission.all.each do |p|
      puts "updating permission #{counter +=1} of #{total_perms}"
      p.entity_id = User.find(p.user_id).entity.id
      p.save!
    end
    counter = 0
    total_perms = DerivedPermission.count
    DerivedPermission.all.each do |p|
      puts "updating derived permission #{counter +=1} of #{total_perms}"
      p.entity_id = User.find(p.user_id).entity.id
      p.save!
    end

    change_column :permissions, :entity_id, :integer, :null => false
    change_column :derived_permissions, :entity_id, :integer, :null => false

    remove_column :permissions, :user_id
    remove_column :derived_permissions, :user_id

    Permission.reset_column_information
    DerivedPermission.reset_column_information
    # create derived permissions for existing records
    counter = 0
    total_perms = Permission.count
    Permission.all.each do |permission|
      puts "updating permision #{counter +=1} of #{total_perms}"
      permission.update_derived_permissions
    end
  end

  def self.down
    add_column :permissions, :user_id, :integer
    add_column :derived_permissions, :user_id, :integer

    Permission.reset_column_information
    DerivedPermission.reset_column_information

    Permission.all.each do |p|
      entity = Entity.find(p.entity_id)
      if entity.entity_target.class == User
        p.user_id = entity.entity_target.id
        p.save!
      end
    end
    DerivedPermission.all.each do |p|
      entity = Entity.find(p.entity_id)
      if entity.entity_target.class == User
        p.user_id = entity.entity_target.id
        p.save!
      end
    end

    change_column :permissions, :user_id, :integer, :null => false
    change_column :derived_permissions, :user_id, :integer, :null => false

    remove_column :permissions, :entity_id
    remove_column :derived_permissions, :entity_id

    Permission.reset_column_information
    DerivedPermission.reset_column_information
  end
end
