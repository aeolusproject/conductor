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

class PrivilegeModelRefactor < ActiveRecord::Migration


  def self.up
    # remove old privileges and role mapping
    drop_table :privileges_roles
    drop_table :privileges

    # new privilege model
    create_table :privileges do |t|
      t.integer :role_id,      :null => false
      t.string  :target_type, :null => false
      t.string  :action, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end

  end

  def self.down
    drop_table :privileges
    create_table :privileges do |t|
      t.string  :name, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end
    create_table :privileges_roles, :id => false do |t|
      t.integer :privilege_id, :null => false
      t.integer :role_id,      :null => false
    end
  end
end
