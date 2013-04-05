# This migration comes from alberich (originally 20121023233648)
class CreateAlberichPermissionSessions < ActiveRecord::Migration
  def change
    create_table :alberich_permission_sessions do |t|
      t.integer :user_id, :null => false
      t.string :session_id, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end
end
