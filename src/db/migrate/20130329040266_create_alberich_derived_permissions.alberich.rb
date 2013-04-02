# This migration comes from alberich (originally 20130107043252)
class CreateAlberichDerivedPermissions < ActiveRecord::Migration
  def change
    create_table :alberich_derived_permissions do |t|
      t.integer :permission_id, :null => false
      t.integer :role_id, :null => false
      t.integer :entity_id, :null => false
      t.integer  :permission_object_id
      t.string   :permission_object_type
      t.integer :lock_version, :default => 0

      t.timestamps
    end
    add_index :alberich_derived_permissions, :permission_id
    add_index :alberich_derived_permissions,
      [:permission_object_id, :permission_object_type],
      :name => 'index_alberich_derived_permissions_on_perm_obj'
  end
end
