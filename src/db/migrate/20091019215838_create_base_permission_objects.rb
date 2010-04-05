class CreateBasePermissionObjects < ActiveRecord::Migration
  def self.up
    create_table :base_permission_objects do |t|
      t.string  :name, :null => false
      t.timestamps
    end

    BasePermissionObject.new({:name => "general_permission_scope"}).save!
  end

  def self.down
    drop_table :base_permission_objects
  end
end
