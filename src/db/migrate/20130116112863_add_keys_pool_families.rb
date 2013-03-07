class AddKeysPoolFamilies < ActiveRecord::Migration
  def change
    add_foreign_key "pool_families", "quotas", :name => "pool_families_quota_id_fk"
  end
end
