class CreateViewStates < ActiveRecord::Migration
  def self.up
    create_table :view_states do |t|
      t.integer :user_id
      t.string :name, :null => false
      t.string :controller, :null => false
      t.string :action, :null => false
      t.text :state

      t.timestamps
    end
  end

  def self.down
    drop_table :view_states
  end
end
