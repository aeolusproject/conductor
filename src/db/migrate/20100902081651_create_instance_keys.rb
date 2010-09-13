class CreateInstanceKeys < ActiveRecord::Migration
  def self.up
    create_table :instance_keys do |t|
      t.integer :cloud_account_id, :null => false
      t.string  :name, :null => false
      t.text    :pem
      t.timestamps
    end
  end

  def self.down
    drop_table :instance_keys
  end
end
