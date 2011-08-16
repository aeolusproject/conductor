class AddDeltacloudProviderToProvider < ActiveRecord::Migration
  def self.up
    add_column :providers, :deltacloud_provider, :string
  end

  def self.down
    remove_column :providers, :deltacloud_provider
  end
end
