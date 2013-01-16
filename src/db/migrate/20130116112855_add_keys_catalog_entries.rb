class AddKeysCatalogEntries < ActiveRecord::Migration
  def change
    add_foreign_key "catalog_entries", "catalogs", :name => "catalog_entries_catalog_id_fk"
    add_foreign_key "catalog_entries", "deployables", :name => "catalog_entries_deployable_id_fk"
  end
end
