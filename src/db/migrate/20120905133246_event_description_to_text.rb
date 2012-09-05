class EventDescriptionToText < ActiveRecord::Migration
  def up
    self.change_column :events, :description, :text
  end

  def down
    self.change_column :events, :description, :string
  end
end
