class AddTargetIdColumnToLegacyImages < ActiveRecord::Migration

  PROVIDER_TYPES = { 0 => "Mock", 1 => "Amazon EC2", 2 => "GoGrid", 3 => "Rackspace", 4 => "RHEV-M", 5 => "OpenNebula" }
  INVERTED_PROVIDER_TYPES = PROVIDER_TYPES.invert

  def self.up
    add_column :legacy_images, :provider_type_id, :integer, :null => false, :default => 100
    remove_column :legacy_images, :target  end

  def self.down
    add_column :legacy_images, :target, :integer
    remove_column :legacy_images, :provider_type_id
  end
end
