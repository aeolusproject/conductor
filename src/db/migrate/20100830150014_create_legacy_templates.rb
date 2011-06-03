class CreateLegacyTemplates < ActiveRecord::Migration
  def self.up
    create_table :legacy_templates do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :platform
      t.string  :platform_version
      t.string  :architecture
      t.text    :summary
      t.boolean :complete, :default => false
      t.boolean :uploaded, :default => false
      t.boolean :imported, :default => false
      t.integer :legacy_images_count
      t.timestamps
    end
  end

  def self.down
    drop_table :legacy_templates
  end
end
