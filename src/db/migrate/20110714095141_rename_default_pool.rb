class RenameDefaultPool < ActiveRecord::Migration
  def self.up
    if pool = Pool.find_by_name("default_pool")
      pool.update_attribute(:name,"Default")
    end
  end

  def self.down
    if pool = Pool.find_by_name("Default")
      pool.update_attribute(:name,"default_pool")
    end
  end
end
