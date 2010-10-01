#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table  :instances do |t|
      t.string    :external_key
      t.string    :name, :null => false, :limit => 1024
      t.integer   :hardware_profile_id, :null => false
      t.integer   :template_id, :null => false
      t.integer   :realm_id
      t.integer   :owner_id
      t.integer   :pool_id, :null => false
      t.integer   :cloud_account_id
      t.string    :public_address
      t.string    :private_address
      t.string    :state
      t.string    :condor_job_id
      t.string    :last_error
      t.integer   :instance_key_id
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

  def self.down
    drop_table :instances
  end
end
