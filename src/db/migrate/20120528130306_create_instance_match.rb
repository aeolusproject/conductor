class CreateInstanceMatch < ActiveRecord::Migration
  def self.up
    create_table :instance_matches do |t|
      t.integer :pool_family_id
      t.integer :provider_account_id
      t.integer :hardware_profile_id
      t.string  :provider_image
      t.integer :realm_id
      t.integer :instance_id
      t.string  :error
      t.timestamps
    end
  end

  def self.down
    drop_table :instance_matches
  end
end
