class RenameCloudAccountIdForInstances < ActiveRecord::Migration
  def self.up
    rename_column :instances, :cloud_account_id, :provider_account_id
  end

  def self.down
    rename_column :instances, :provider_account_id, :cloud_account_id
  end
end
