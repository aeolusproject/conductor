class AddKeysCatalogs < ActiveRecord::Migration
  def change
    add_foreign_key "catalogs", "pool_families", :name => "catalogs_pool_family_id_fk"
    add_foreign_key "catalogs", "pools", :name => "catalogs_pool_id_fk"
  end
end
