class UpdateInstances < ActiveRecord::Migration
  def self.up
    change_table :instances do |t|
      t.integer :legacy_assembly_id
      t.integer :deployment_id
      t.change   :legacy_template_id, :integer, :null => true
    end

    create_table :instances_legacy_assemblies, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    change_table :instances do |t|
      t.remove :legacy_assembly_id, :deployment_id
      t.change   :legacy_template_id, :integer, :null => false
    end
  end
end
