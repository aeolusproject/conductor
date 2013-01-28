class AddKeysInstanceMatch < ActiveRecord::Migration
  def change
    add_foreign_key "instance_matches", "hardware_profiles", :name => "instance_matches_hardware_profile_id_fk"
    add_foreign_key "instance_matches", "instances", :name => "instance_matches_instance_id_fk"
    add_foreign_key "instance_matches", "pool_families", :name => "instance_matches_pool_family_id_fk"
    add_foreign_key "instance_matches", "provider_accounts", :name => "instance_matches_provider_account_id_fk"
    add_foreign_key "instance_matches", "provider_realms", :name => "instance_matches_provider_realm_id_fk"
  end
end
