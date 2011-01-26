class FrontendRealms < ActiveRecord::Migration
  def self.up
    drop_table :realm_map
    create_table :frontend_realms do |t|
      t.string  :name, :null => false, :limit => 1024
      t.integer :lock_version, :default => 0
      t.timestamps
    end
    create_table :realm_backend_targets do |t|
      t.integer :realm_or_provider_id, :null => false
      t.string  :realm_or_provider_type, :null => false
      t.integer :frontend_realm_id, :null => false
    end
    rename_column :instances, :realm_id, :frontend_realm_id
    # delete all 'frontend' realms
    Realm.all(:conditions => {:provider_id => nil}).each {|r| r.destroy}
  end

  def self.down
    drop_table :frontend_realms
    drop_table :realm_backend_targets
    create_table "realm_map", :force => true, :id => false do |t|
      t.column "frontend_realm_id", :integer
      t.column "backend_realm_id", :integer
    end
    rename_column :instances, :frontend_realm_id, :realm_id
  end
end
