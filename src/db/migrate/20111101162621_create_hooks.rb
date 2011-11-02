class CreateHooks < ActiveRecord::Migration
  def self.up
    create_table :hooks do |t|
      t.string :uri
      t.string :version

      t.timestamps
    end
  end

  def self.down
    drop_table :hooks
  end
end
