class UpdateDeployment < ActiveRecord::Migration
  def self.up
    add_column :deployments, :frontend_realm_id, :integer
  end

  def self.down
    remove_column :deployments, :frontend_realm_id
  end
end
