class UpdateDeployables < ActiveRecord::Migration
  def self.up
    change_table :legacy_deployables do |t|
      t.integer :lock_version, :default => 0
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.text    :summary
      t.boolean :uploaded, :default => false
    end

    create_table :legacy_assemblies_legacy_deployables, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    drop_table :legacy_assemblies_legacy_deployables
    change_table :legacy_deployables do |t|
      t.remove  :lock_version, :uuid, :xml, :uri, :summary, :uploaded
    end
  end
end
