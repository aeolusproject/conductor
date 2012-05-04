class AddDeploymentState < ActiveRecord::Migration
  def self.up
    add_column :deployments, :state, :string
  end

  def self.down
    remove_column :deployments, :state
  end
end
