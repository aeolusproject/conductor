class RenameCloudAccountsPoolFamiliesToProviderAccountsPoolFamilies < ActiveRecord::Migration
  def self.up
    rename_table :cloud_accounts_pool_families, :pool_families_provider_accounts
    rename_column :pool_families_provider_accounts, :cloud_account_id, :provider_account_id
  end

  def self.down
    rename_column :pool_families_provider_accounts, :provider_account_id, :cloud_account_id
    rename_table :pool_families_provider_accounts, :cloud_accounts_pool_families
  end
end
