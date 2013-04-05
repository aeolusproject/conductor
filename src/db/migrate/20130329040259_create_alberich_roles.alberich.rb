# This migration comes from alberich (originally 20120925162242)
class CreateAlberichRoles < ActiveRecord::Migration
  def change
    create_table :alberich_roles do |t|
      t.string  :name, :null => false
      t.string  :scope, :null => false
      t.integer :lock_version, :default => 0
      t.boolean  :assign_to_owner, :default => false

      t.timestamps
    end
  end
end
