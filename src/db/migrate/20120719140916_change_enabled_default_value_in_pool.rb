class ChangeEnabledDefaultValueInPool < ActiveRecord::Migration
  def self.up
    change_column :pools, :enabled, :boolean, :default => true
  end

  def self.down
    change_column :pools, :enabled, :boolean, :default => false
  end
end
