class AddKeysPools < ActiveRecord::Migration
  def change
    add_foreign_key "pools", "pool_families", :name => "pools_pool_family_id_fk"
    add_foreign_key "pools", "quotas", :name => "pools_quota_id_fk"
  end
end
