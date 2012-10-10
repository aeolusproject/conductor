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

class FrontendRealms < ActiveRecord::Migration
  class Realm < ActiveRecord::Base
  end

  def self.up
    drop_table :realm_map
    create_table :frontend_realms do |t|
      t.string  :name, :null => false, :limit => 1024
      t.integer :lock_version, :default => 0
      t.timestamps
    end
    create_table :realm_backend_targets do |t|
      t.integer :realm_or_provider_id, :null => false
      t.string  :realm_or_provider_type, :null => false
      t.integer :frontend_realm_id, :null => false
    end
    rename_column :instances, :realm_id, :frontend_realm_id
    # delete all 'frontend' realms
    Realm.all(:conditions => {:provider_id => nil}).each {|r| r.destroy}
  end

  def self.down
    drop_table :frontend_realms
    drop_table :realm_backend_targets
    create_table "realm_map", :force => true, :id => false do |t|
      t.column "frontend_realm_id", :integer
      t.column "backend_realm_id", :integer
    end
    rename_column :instances, :frontend_realm_id, :realm_id
  end
end
