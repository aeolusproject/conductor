class UpdateInstances < ActiveRecord::Migration
  def self.up
    change_table :instances do |t|
      t.integer :assembly_id
      t.integer :deployment_id
      t.change   :template_id, :integer, :null => true
    end

    create_table :assemblies_instances, :id => false do |t|
      t.integer :assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    change_table :instances do |t|
      t.remove :assembly_id, :deployment_id
      t.change   :template_id, :integer, :null => false
    end
  end
end
