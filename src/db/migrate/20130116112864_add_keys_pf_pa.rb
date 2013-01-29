class AddKeysPfPa < ActiveRecord::Migration
  def change
    add_foreign_key "pool_families_provider_accounts", "pool_families", :name => "pool_families_provider_accounts_pool_family_id_fk"
    add_foreign_key "pool_families_provider_accounts", "provider_accounts", :name => "pool_families_provider_accounts_provider_account_id_fk"
  end
end
