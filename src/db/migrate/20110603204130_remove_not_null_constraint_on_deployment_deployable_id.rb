class RemoveNotNullConstraintOnDeploymentDeployableId < ActiveRecord::Migration
  def self.up
    change_column :deployments, :legacy_deployable_id, :integer, :null => true
  end

  def self.down
    change_column :deployments, :legacy_deployable_id, :integer, :null => false
  end
end
