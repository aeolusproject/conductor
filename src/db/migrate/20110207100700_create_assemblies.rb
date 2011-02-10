class CreateAssemblies < ActiveRecord::Migration
  def self.up
    create_table :assemblies do |t|
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
    create_table :assemblies_templates, :id => false do |t|
      t.integer :assembly_id,  :null => false
      t.integer :template_id,  :null => false
    end
  end

  def self.down
    drop_table :assemblies_templates
    drop_table :assemblies
  end
end
