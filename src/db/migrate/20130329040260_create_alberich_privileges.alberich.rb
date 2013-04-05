# This migration comes from alberich (originally 20121022223626)
class CreateAlberichPrivileges < ActiveRecord::Migration
  def change
    create_table :alberich_privileges do |t|
      t.integer :role_id,      :null => false
      t.string :target_type,   :null => false
      t.string :action,        :null => false

      t.integer :lock_version, :default => 0
      t.timestamps
    end
  end
end
