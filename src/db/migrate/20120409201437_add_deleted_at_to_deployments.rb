class AddDeletedAtToDeployments < ActiveRecord::Migration
  def self.up
    add_column :deployments, :deleted_at, :datetime
    add_index :deployments, :deleted_at
  end

  def self.down
    remove_column :deployments, :deleted_at
  end
end
