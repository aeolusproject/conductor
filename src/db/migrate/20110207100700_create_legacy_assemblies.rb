class CreateLegacyAssemblies < ActiveRecord::Migration
  def self.up
    create_table :legacy_assemblies do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :architecture
      t.text    :summary
      t.boolean :uploaded, :default => false
      t.integer   :lock_version, :default => 0
      t.timestamps
    end
    create_table :legacy_assemblies_legacy_templates, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_template_id,  :null => false
    end
  end

  def self.down
    drop_table :legacy_assemblies_legacy_templates
    drop_table :legacy_assemblies
  end
end
