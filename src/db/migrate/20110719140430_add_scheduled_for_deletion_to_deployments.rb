class AddScheduledForDeletionToDeployments < ActiveRecord::Migration
  def self.up
    add_column(:deployments, :scheduled_for_deletion,
               :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column :deployments, :scheduled_for_deletion
  end
end
