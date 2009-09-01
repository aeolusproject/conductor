class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table :instances do |t|
      t.string  :external_key
      t.string  :name, :null => false, :limit => 1024
      t.integer :flavor_id, :null => false
      t.integer :image_id, :null => false
      t.integer :realm_id
      t.integer :portal_pool_id, :null => false
      t.string  :public_address
      t.string  :private_address
      t.string  :state
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :instances
  end
end
