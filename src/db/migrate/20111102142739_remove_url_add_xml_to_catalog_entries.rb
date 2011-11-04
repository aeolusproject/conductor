class RemoveUrlAddXmlToCatalogEntries < ActiveRecord::Migration
  def self.up
    remove_column :catalog_entries, :url
    add_column :catalog_entries, :xml, :text
    add_column :catalog_entries, :xml_filename, :string
    execute "DELETE from catalog_entries"
  end

  def self.down
    remove_column :catalog_entries, :xml
    remove_column :catalog_entries, :xml_filename
    add_column :catalog_entries, :url, :string
    execute "DELETE from catalog_entries"
  end
end
