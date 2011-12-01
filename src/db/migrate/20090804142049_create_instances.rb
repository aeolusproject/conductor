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

class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table  :instances do |t|
      t.string    :external_key
      t.string    :name, :null => false, :limit => 1024
      t.integer   :hardware_profile_id, :null => false
      t.integer   :legacy_template_id, :null => false
      t.integer   :realm_id
      t.integer   :owner_id
      t.integer   :pool_id, :null => false
      t.integer   :cloud_account_id
      t.integer   :instance_hwp_id
      t.string    :public_address
      t.string    :private_address
      t.string    :state
      t.string    :condor_job_id
      t.string    :last_error
      t.integer   :lock_version, :default => 0
      t.integer   :acc_pending_time, :default => 0
      t.integer   :acc_running_time, :default => 0
      t.integer   :acc_shutting_down_time, :default => 0
      t.integer   :acc_stopped_time, :default => 0
      t.timestamp :time_last_pending
      t.timestamp :time_last_running
      t.timestamp :time_last_shutting_down
      t.timestamp :time_last_stopped
      t.string    :public_ip_addresses
      t.timestamps
    end
  end

  create_table :instance_hwps do |t|
    t.string :memory
    t.string :cpu
    t.string :architecture
    t.string :storage
    t.integer :lock_version, :default => 0
  end

  def self.down
    drop_table :instances
    drop_table :instance_hwps
  end
end
