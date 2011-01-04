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
