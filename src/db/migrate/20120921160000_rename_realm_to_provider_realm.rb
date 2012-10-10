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

class RenameRealmToProviderRealm < ActiveRecord::Migration
  def self.up
    rename_table :realms, :provider_realms
    if ActiveRecord::Base.connection.tables.include?('provider_accounts_provider_realms')
      drop_table :provider_accounts_provider_realms
    end
    rename_table :provider_accounts_realms, :provider_accounts_provider_realms
    rename_column :provider_accounts_provider_realms, :realm_id, :provider_realm_id
    Privilege.where(:target_type => 'Realm').each do |priv|
      priv.target_type = 'FrontendRealm'
      priv.save!
    end
    rename_column :realm_backend_targets, :realm_or_provider_id, :provider_realm_or_provider_id
    rename_column :realm_backend_targets, :realm_or_provider_type, :provider_realm_or_provider_type
    rename_column :instance_matches, :realm_id, :provider_realm_id
    rename_column :deployments, :realm_id, :provider_realm_id
  end

  def self.down
    rename_column :deployments, :provider_realm_id, :realm_id
    rename_column :instance_matches, :provider_realm_id, :realm_id
    rename_column :realm_backend_targets, :provider_realm_or_provider_type, :realm_or_provider_type
    rename_column :realm_backend_targets, :provider_realm_or_provider_id, :realm_or_provider_id
    Privilege.where(:target_type => 'FrontendRealm').each do |priv|
      priv.target_type = 'Realm'
      priv.save!
    end
    rename_column :provider_accounts_provider_realms, :provider_realm_id, :realm_id
    rename_table :provider_accounts_provider_realms, :provider_accounts_realms
    rename_table :provider_realms, :realms
  end
end
