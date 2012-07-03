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
class CreateDerivedPermissions < ActiveRecord::Migration
  def self.up
    create_table :derived_permissions do |t|
      t.integer :permission_id, :null => false
      t.integer :role_id, :null => false
      t.integer :user_id, :null => false
      t.integer :permission_object_id
      t.string  :permission_object_type
      t.integer :lock_version, :default => 0

      t.timestamps
    end
    add_index :derived_permissions, :permission_id
    add_index :derived_permissions,
      [:permission_object_id, :permission_object_type],
      :name => 'index_derived_permissions_on_permission_object'
  end

  def self.down
    drop_table :derived_permissions
  end
end
