class AddKeysDeployables < ActiveRecord::Migration
  def change
    add_foreign_key "deployables", "users", :name => "deployables_owner_id_fk", :column => "owner_id"
    add_foreign_key "deployables", "pool_families", :name => "deployables_pool_family_id_fk"
  end
end
