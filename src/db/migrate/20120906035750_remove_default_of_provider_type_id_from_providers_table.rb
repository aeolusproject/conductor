class RemoveDefaultOfProviderTypeIdFromProvidersTable < ActiveRecord::Migration
  def self.up
    change_column_default(:providers, :provider_type_id, nil)
  end

  def self.down
    change_column_default(:providers, :provider_type_id, 100)
  end
end
