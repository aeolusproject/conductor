class DropHooks < ActiveRecord::Migration
  def up
    drop_table :hooks
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
