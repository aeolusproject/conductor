class AddCondorCloudProviderType < ActiveRecord::Migration

  def self.up
    provider_type = ProviderType.create!(:name => "CondorCloud", :build_supported => true, :codename =>"condorcloud")
    CredentialDefinition.create!(:name => 'username', :label => 'API Key', :input_type => 'text', :provider_type_id => provider_type.id)
    CredentialDefinition.create!(:name => 'password', :label => 'Secret', :input_type => 'password', :provider_type_id => provider_type.id)

  end

  def self.down
  end

end
