class AddKeysInstance < ActiveRecord::Migration
  def change
    add_foreign_key "instances", "deployments", :name => "instances_deployment_id_fk"
    #
    # The following constraints cannot be added due to the partial delete (acts_as_paranoid) being used on
    # Instance model.
    #
    #add_foreign_key "instances", "frontend_realms", :name => "instances_frontend_realm_id_fk"
    #add_foreign_key "instances", "hardware_profiles", :name => "instances_hardware_profile_id_fk"
    #add_foreign_key "instances", "instance_hwps", :name => "instances_instance_hwp_id_fk"
    #add_foreign_key "instances", "users", :name => "instances_owner_id_fk", :column => "owner_id"
    #add_foreign_key "instances", "pool_families", :name => "instances_pool_family_id_fk"
    #add_foreign_key "instances", "pools", :name => "instances_pool_id_fk"
    #add_foreign_key "instances", "provider_accounts", :name => "instances_provider_account_id_fk"
    #add_foreign_key "instances", "hardware_profiles", :name => "instances_provider_hardware_profile_id_fk", :column => "provider_hardware_profile_id"
  end
end
