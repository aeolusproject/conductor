class CreateFlavors < ActiveRecord::Migration
  def self.up
    create_table :flavors do |t|
      t.string  :external_key, :null => false
      t.string  :name, :null => false, :limit => 1024
      t.float   :memory, :null => false
      t.float   :storage, :null => false
      t.string  :architecture, :null => false
      t.integer :provider_id, :null => false
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :flavors
  end
end
