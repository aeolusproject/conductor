class AddVmwareVsphereProvider < ActiveRecord::Migration
  def self.up
    if not ProviderType.find_by_codename('vmware') and ProviderType.count > 0
      provider_type = ProviderType.create!(:name => "VMWare vSphere", :build_supported => true, :codename =>"vmware")
      CredentialDefinition.create!(:name => 'username', :label => 'Username', :input_type => 'text', :provider_type_id => provider_type.id)
      CredentialDefinition.create!(:name => 'password', :label => 'Password', :input_type => 'password', :provider_type_id => provider_type.id)
    end
  end

  def self.down
    ProviderType.destroy_all(:codename=>"vmware")
  end
end
