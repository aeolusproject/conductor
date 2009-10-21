class CreateBasePortalObjects < ActiveRecord::Migration
  def self.up
    create_table :base_portal_objects do |t|
      t.string  :name, :null => false
      t.timestamps
    end

    BasePortalObject.new({:name => "general_permission_scope"}).save!
  end

  def self.down
    drop_table :base_portal_objects
  end
end
