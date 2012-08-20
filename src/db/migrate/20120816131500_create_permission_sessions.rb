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
class CreatePermissionSessions < ActiveRecord::Migration
  def self.up
    create_table :permission_sessions do |t|
      t.references :user, :null => false
      t.string :session_id, :null => false

      t.integer :lock_version, :default => 0

      t.timestamps
    end
    #delete any existing session entities, as they'll no longer be valid
    SessionEntity.destroy_all
    remove_column :session_entities, :session_id
    add_column :session_entities, :permission_session_id, :integer
    change_column :session_entities, :permission_session_id, :integer, :null => false
  end

  def self.down
    SessionEntity.destroy_all
    remove_column :session_entities, :permission_session_id
    add_column :session_entities, :session_id, :string
    change_column :session_entities, :session_id, :string, :null => false

    drop_table :permission_sessions
  end
end
