class AddPartialLaunchToDeployment < ActiveRecord::Migration
  def self.up
    add_column :deployments, :partial_launch, :boolean, :default => false
    Deployment.unscoped.all.each do |d|
      d.update_attribute(:partial_launch, true)
    end
  end

  def self.down
    remove_column :deployments, :partial_launch
  end
end
