class AddOwnerId < ActiveRecord::Migration
  def self.up
    add_column :legacy_templates, :owner_id, :integer
    add_column :legacy_assemblies, :owner_id, :integer
    add_column :legacy_deployables, :owner_id, :integer
  end

  def self.down
    remove_column :legacy_templates, :owner_id
    remove_column :legacy_assemblies, :owner_id
    remove_column :legacy_deployables, :owner_id
  end
end
