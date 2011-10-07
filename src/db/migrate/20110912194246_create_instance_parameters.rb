class CreateInstanceParameters < ActiveRecord::Migration
  def self.up
    create_table :instance_parameters do |t|
      t.string :service
      t.string :name
      t.string :type
      t.string :value
      t.references :instance

      t.timestamps
    end
  end

  def self.down
    drop_table :instance_parameters
  end
end
