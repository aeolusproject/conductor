class AddProviderTypeIdToProvider < ActiveRecord::Migration

  PROVIDER_TYPES = { 0 => "Mock", 1 => "Amazon EC2", 2 => "GoGrid", 3 => "Rackspace", 4 => "RHEV-M", 5 => "OpenNebula" }
  INVERTED_PROVIDER_TYPES = PROVIDER_TYPES.invert

  def self.up
    load_provider_types
    add_column :providers, :provider_type_id, :integer, :null => false, :default => 100
    rename_column :providers, :provider_type, :provider_type_int
    transform_provider_type_column
    remove_column :providers, :provider_type_int
  end

  def self.down
    add_column :providers, :provider_type_temporary, :integer
    transform_provider_type_column_back
    rename_column :providers, :provider_type_temporary, :provider_type
    remove_column :providers, :provider_type_id
  end

  def self.load_provider_types
    if ProviderType.all.empty?
      ProviderType.create!(:name => "Mock", :build_supported => true, :codename =>"mock", :ssh_user => "ec2-user", :home_dir => "/home/ec2-user")
      ProviderType.create!(:name => "Amazon EC2", :build_supported => true, :codename =>"ec2")
      ProviderType.create!(:name => "GoGrid", :codename =>"gogrid")
      ProviderType.create!(:name => "Rackspace", :codename =>"rackspace")
      ProviderType.create!(:name => "RHEV-M", :codename =>"rhevm")
      ProviderType.create!(:name => "OpenNebula", :codename =>"opennebula")
    end
  end

  def self.transform_provider_type_column
    Provider.all.each do |provider|
      provider.update_attribute(:provider_type_id, ProviderType.first(:conditions => {:name => PROVIDER_TYPES[provider.provider_type_int]}).id)
    end
  end

  def self.transform_provider_type_column_back
    Provider.all.each do |provider|
      provider.update_attribute(:provider_type_temporary, INVERTED_PROVIDER_TYPES[provider.provider_type.name])
    end
  end
end
