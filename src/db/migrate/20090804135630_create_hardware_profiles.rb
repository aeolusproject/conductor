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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class CreateHardwareProfiles < ActiveRecord::Migration
  def self.up
    create_table :hardware_profile_properties do |t|
      t.string  :name, :null => false
      t.string  :kind, :null => false
      t.string  :unit, :null => false
      t.string  :value, :null => false
      t.string  :range_first
      t.string  :range_last
      t.integer :lock_version, :default => 0
      t.timestamps
    end

    create_table :property_enum_entries do |t|
      t.integer :hardware_profile_property_id, :null => false
      t.string :value, :null => false
      t.integer :lock_version, :default => 0
      t.timestamps
    end

    create_table :hardware_profiles do |t|
      t.string  :external_key
      t.string  :name, :null => false, :limit => 1024
      t.integer :memory_id
      t.integer :storage_id
      t.integer :cpu_id
      t.integer :architecture_id
      t.integer :provider_id
      t.integer :lock_version, :default => 0
      t.timestamps
    end

    create_table "hardware_profile_map", :force => true, :id => false do |t|
      t.column "conductor_hardware_profile_id", :integer
      t.column "provider_hardware_profile_id", :integer
    end
  end

  def self.down
    drop_table :hardware_profile_map
    drop_table :hardware_profiles
  end
end
