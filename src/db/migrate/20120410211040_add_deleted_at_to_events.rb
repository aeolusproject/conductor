class AddDeletedAtToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :deleted_at, :datetime
    add_index :events, :deleted_at
  end

  def self.down
    remove_column :events, :deleted_at
  end
end
