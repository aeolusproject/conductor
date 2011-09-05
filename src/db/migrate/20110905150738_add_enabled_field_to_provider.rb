class AddEnabledFieldToProvider < ActiveRecord::Migration
  def self.up
    add_column :providers, :enabled, :boolean, :null => false, :default => true
    Provider.update_all(:enabled => true)
  end

  def self.down
    remove_column :providers, :enabled
  end
end
