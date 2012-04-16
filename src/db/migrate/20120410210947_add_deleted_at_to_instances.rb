class AddDeletedAtToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :deleted_at, :datetime
    add_index :instances, :deleted_at
  end

  def self.down
    remove_column :instances, :deleted_at
  end
end
