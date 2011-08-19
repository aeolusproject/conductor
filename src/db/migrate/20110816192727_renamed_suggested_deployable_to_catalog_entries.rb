class RenamedSuggestedDeployableToCatalogEntries < ActiveRecord::Migration
  def self.up
    rename_table :suggested_deployables, :catalog_entries
    add_column :catalog_entries, :catalog_id, :integer, :null => false
  end

  def self.down
    rename_table :catalog_entries, :suggested_deployables
    drop_column :catalog_id
  end
end
