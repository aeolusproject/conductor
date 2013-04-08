# This migration comes from alberich (originally 20121204205213)
class CreateAlberichSessionEntities < ActiveRecord::Migration
  def change
    create_table :alberich_session_entities do |t|
      t.integer :user_id, :null => false
      t.integer :entity_id, :null => false
      t.integer :permission_session_id, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end
end
