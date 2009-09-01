class CreateCloudAccounts < ActiveRecord::Migration
  def self.up
    create_table :cloud_accounts do |t|
      t.string :username, :null => false
      t.string :password, :null => false
      t.integer :provider_id, :null => false
      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :cloud_accounts
  end
end
