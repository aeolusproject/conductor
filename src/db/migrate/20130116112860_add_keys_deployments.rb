class AddKeysDeployments < ActiveRecord::Migration
  def change
    # The following constraints cannot be added due to the partial delete (acts_as_paranoid) being used on
    # Deployment model. FIXME: #387
    #
    add_foreign_key "deployments", "frontend_realms", :name => "deployments_frontend_realm_id_fk"
    add_foreign_key "deployments", "users", :name => "deployments_owner_id_fk", :column => "owner_id"
    add_foreign_key "deployments", "pool_families", :name => "deployments_pool_family_id_fk"
    add_foreign_key "deployments", "pools", :name => "deployments_pool_id_fk"
    add_foreign_key "deployments", "provider_realms", :name => "deployments_provider_realm_id_fk"
  end
end
