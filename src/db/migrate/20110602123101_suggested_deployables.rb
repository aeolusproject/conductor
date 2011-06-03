class SuggestedDeployables < ActiveRecord::Migration
  def self.up
    create_table  :suggested_deployables do |t|
      t.string  :name, :null => false, :limit => 1024
      t.text    :description, :null => false
      t.string  :url
      t.integer :owner_id
    end
  end

  def self.down
    drop_table :suggested_deployables
  end
end
