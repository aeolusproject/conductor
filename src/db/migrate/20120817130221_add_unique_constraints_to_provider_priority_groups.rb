class AddUniqueConstraintsToProviderPriorityGroups < ActiveRecord::Migration
  def self.up
    add_index :provider_priority_groups, [:name, :pool_id], :unique => true
    add_index :provider_priority_groups, [:score, :pool_id], :unique => true
  end

  def self.down
    remove_index :provider_priority_groups, [:name, :pool_id]
    remove_index :provider_priority_groups, [:score, :pool_id]
  end
end
