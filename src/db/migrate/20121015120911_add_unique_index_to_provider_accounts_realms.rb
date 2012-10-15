class AddUniqueIndexToProviderAccountsRealms < ActiveRecord::Migration
  def change
    add_index :provider_accounts_realms, [:provider_account_id, :realm_id], :unique => true, :name => 'provider_accounts_realms_unique_key'
  end
end
