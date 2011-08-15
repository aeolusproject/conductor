class RemovePolymorphicInstanceKey < ActiveRecord::Migration
  def self.up
    remove_column :instance_keys, :instance_key_owner_type
    rename_column :instance_keys, :instance_key_owner_id, :instance_id
  end

  def self.down
    add_column :instance_keys, :instance_key_owner_type, :string
    rename_column :instance_keys, :instance_id, :instance_key_owner_id
  end
end
