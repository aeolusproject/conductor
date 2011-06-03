class CreateDeployables < ActiveRecord::Migration
  def self.up
    create_table :legacy_deployables do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :legacy_deployables
  end
end
