class AddUniqueIndexToProviderAccountsRealms < ActiveRecord::Migration
  def change
    add_index :provider_accounts_provider_realms, [:provider_account_id, :provider_realm_id], :unique => true, :name => 'provider_accounts_provider_realms_unique_key'
  end
end
