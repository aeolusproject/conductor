class CreateDeployments < ActiveRecord::Migration
  def self.up
    create_table :deployments do |t|
      t.string    :name, :null => false, :limit => 1024
      t.integer   :realm_id
      t.integer   :owner_id
      t.integer   :pool_id, :null => false
      t.integer   :deployable_id, :null => false
      t.integer   :lock_version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :deployments
  end
end
