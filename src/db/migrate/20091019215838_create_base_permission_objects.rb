class CreateBasePermissionObjects < ActiveRecord::Migration
  def self.up
    create_table :base_permission_objects do |t|
      t.string  :name, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :base_permission_objects
  end
end
