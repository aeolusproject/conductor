class CreateInstanceKeys < ActiveRecord::Migration
  def self.up
    create_table :instance_keys do |t|
      t.integer :instance_key_owner_id, :null => false
      t.string  :instance_key_owner_type, :null => false
      t.string  :name, :null => false
      t.text    :pem
      t.timestamps
    end
  end

  def self.down
    drop_table :instance_keys
  end
end
