class AddTargetIdColumnToImages < ActiveRecord::Migration

  PROVIDER_TYPES = { 0 => "Mock", 1 => "Amazon EC2", 2 => "GoGrid", 3 => "Rackspace", 4 => "RHEV-M", 5 => "OpenNebula" }
  INVERTED_PROVIDER_TYPES = PROVIDER_TYPES.invert

  def self.up
    add_column :images, :provider_type_id, :integer, :null => false, :default => 100
    transform_target_column
    remove_column :images, :target  end

  def self.down
    add_column :images, :target, :integer
    transform_target_column_back
    remove_column :images, :provider_type_id
  end

  def self.transform_target_column
    Image.all.each do |image|
      image.update_attribute(:provider_type_id, ProviderType.first(:conditions => {:name => PROVIDER_TYPES[image.target] }).id)
    end
  end

  def self.transform_target_column_back
    Image.all.each do |image|
      image.update_attribute(:target, INVERTED_PROVIDER_TYPES[image.provider_type.name])
    end
  end
end
