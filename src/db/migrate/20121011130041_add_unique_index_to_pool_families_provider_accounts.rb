class AddUniqueIndexToPoolFamiliesProviderAccounts < ActiveRecord::Migration
  def change
    add_index :pool_families_provider_accounts, [:provider_account_id, :pool_family_id], :unique => true, :name => 'pool_fam_prov_acc_uniq_index'
  end
end
