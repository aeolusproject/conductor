class CreateImageDescriptorTargets < ActiveRecord::Migration
  def self.up
    create_table :image_descriptor_targets do |t|
      t.string :name, :null => false
      t.integer :build_id
      t.string :status
      t.integer :image_descriptor_id
      t.timestamps
    end
  end

  def self.down
    drop_table :image_descriptor_targets
  end
end
