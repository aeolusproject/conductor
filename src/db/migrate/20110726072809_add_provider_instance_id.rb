class AddProviderInstanceId < ActiveRecord::Migration
  def self.up
    add_column :instances, :provider_instance_id, :string
  end

  def self.down
    remove_column :instances, :provider_instance_id
  end
end
