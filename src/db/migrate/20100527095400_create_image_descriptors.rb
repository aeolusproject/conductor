class CreateImageDescriptors < ActiveRecord::Migration
  def self.up
    create_table :image_descriptors do |t|
      t.binary :xml, :null => false
      t.string :uri
      t.boolean :complete, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :image_descriptors
  end
end
