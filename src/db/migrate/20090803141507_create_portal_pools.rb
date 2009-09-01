class CreatePortalPools < ActiveRecord::Migration
  def self.up
    create_table :portal_pools do |t|
      t.string :name, :null => false
      t.integer :cloud_account_id, :null => false
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :portal_pools
  end
end
