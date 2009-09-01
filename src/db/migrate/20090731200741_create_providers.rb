class CreateProviders < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.string :name, :null => false
      t.string :cloud_type, :null => false
      t.string :url, :null => false
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :providers
  end
end
