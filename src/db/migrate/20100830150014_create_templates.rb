class CreateTemplates < ActiveRecord::Migration
  def self.up
    create_table :templates do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :platform
      t.text    :summary
      t.boolean :complete, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :templates
  end
end
