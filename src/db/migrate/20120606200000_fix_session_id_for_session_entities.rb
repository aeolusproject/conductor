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
class FixSessionIdForSessionEntities < ActiveRecord::Migration
  def self.up
    rename_column :session_entities, :session_id, :session_db_id
    add_column :session_entities, :session_id, :string
    SessionEntity.reset_column_information
    SessionEntity.all.each do |se|
      begin
        session = ActiveRecord::SessionStore::Session.find(se.session_db_id)
        se.session_id = session.session_id
        se.save!
      rescue
        se.destroy
      end
    end
    remove_column :session_entities, :session_db_id
    change_column :session_entities, :session_id, :string, :null => false
  end

  def self.down
    add_column :session_entities, :session_db_id, :integer
    SessionEntity.reset_column_information
    SessionEntity.each do |se|
      session = ActiveRecord::SessionStore::Session.find_by_session_id(se.session_id)
      if session
        se.session_db_id = session.id
        se.save!
      else
        se.destroy
      end
    end
    remove_column :session_entities, :session_id
    rename_column :session_entities, :session_db_id, :session_id
    change_column :session_entities, :session_id, :integer, :null => false

  end
end
