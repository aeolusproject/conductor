class EventDescriptionToText < ActiveRecord::Migration
  def self.up
    self.change_column :events, :description, :text
  end

  def self.down
    self.change_column :events, :description, :string
  end
end
