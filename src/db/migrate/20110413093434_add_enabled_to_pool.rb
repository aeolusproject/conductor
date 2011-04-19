class AddEnabledToPool < ActiveRecord::Migration
  def self.up
    add_column :pools, :enabled, :boolean, :default => false
    set_enabled
  end

  def self.down
    remove_column :pools, :enabled
  end

  def self.set_enabled
    unless Pool.all.empty?
      Pool.all.each do |pool|
        pool.enabled = true
        pool.save!
      end
    end
  end
end
