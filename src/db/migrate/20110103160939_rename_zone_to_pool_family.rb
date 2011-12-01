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

class RenameZoneToPoolFamily < ActiveRecord::Migration
  def self.up
    rename_table :zones, :pool_families
    rename_table :cloud_accounts_zones, :cloud_accounts_pool_families
    rename_column :cloud_accounts_pool_families, :zone_id, :pool_family_id
    rename_column :pools, :zone_id, :pool_family_id
  end

  def self.down
    rename_column :pools, :zone_id, :pool_family_id
    rename_column :cloud_accounts_pool_families, :pool_family_id, :zone_id
    rename_table :cloud_accounts_pool_families, :cloud_accounts_zones
    rename_table :pool_families, :zones
  end
end
