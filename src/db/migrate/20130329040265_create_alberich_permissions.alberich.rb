# This migration comes from alberich (originally 20121205180518)
class CreateAlberichPermissions < ActiveRecord::Migration
  def change
    create_table :alberich_permissions do |t|
      t.integer :role_id, :null => false
      t.integer :entity_id, :null => false
      t.integer :permission_object_id
      t.string  :permission_object_type
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end
end
