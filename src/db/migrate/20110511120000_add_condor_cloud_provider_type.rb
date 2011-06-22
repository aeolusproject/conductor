class AddCondorCloudProviderType < ActiveRecord::Migration

  def self.up
    if not ProviderType.find_by_codename('condorcloud') and ProviderType.count > 0
      provider_type = ProviderType.create!(:name => "CondorCloud", :build_supported => true, :codename =>"condorcloud")
      CredentialDefinition.create!(:name => 'username', :label => 'API Key', :input_type => 'text', :provider_type_id => provider_type.id)
      CredentialDefinition.create!(:name => 'password', :label => 'Secret', :input_type => 'password', :provider_type_id => provider_type.id)
    end
  end

  def self.down
    ProviderType.destroy_all(:codename =>"condorcloud")
  end

end
