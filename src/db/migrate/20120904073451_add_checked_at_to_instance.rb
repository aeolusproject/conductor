class AddCheckedAtToInstance < ActiveRecord::Migration
  def self.up
    add_column :instances, :checked_at, :datetime, :null => false, :default => Time.now
  end

  def self.down
    remove_column :instances, :checked_at
  end
end
