class AddRealmAvailableColumn < ActiveRecord::Migration
  def self.up
    add_column :realms, :available, :boolean, :null => false, :default => true
    add_column :providers, :available, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :realms, :available
    remove_column :providers, :available
  end
end
