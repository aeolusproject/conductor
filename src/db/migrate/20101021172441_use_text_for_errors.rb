class UseTextForErrors < ActiveRecord::Migration
  def self.up
    change_column :instances, :last_error, :text
  end

  def self.down
    change_column :instances, :last_error, :string
  end
end
