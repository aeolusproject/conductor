class ChangeViewStateIdToUuid < ActiveRecord::Migration
  def self.up
    change_table :view_states do |t|
      t.change :id, :string, :limit => 36
      t.rename :id, :uuid
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
