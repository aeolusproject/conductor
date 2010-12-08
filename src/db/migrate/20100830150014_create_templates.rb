class CreateTemplates < ActiveRecord::Migration
  def self.up
    create_table :templates do |t|
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
      t.integer :images_count
      t.timestamps
    end
  end

  def self.down
    drop_table :templates
  end
end
