class RenameProviderTypeCodename < ActiveRecord::Migration
  def self.up
    rename_column :provider_types, :codename, :deltacloud_driver
  end

  def self.down
    rename_column :provider_types, :deltacloud_driver, :codename
  end
end
