class RemoveBuildSupportedFromProviderTypes < ActiveRecord::Migration
  def self.up
    remove_column :provider_types, :build_supported
  end

  def self.down
    add_column :provider_types, :build_supported, :boolean
  end
end
