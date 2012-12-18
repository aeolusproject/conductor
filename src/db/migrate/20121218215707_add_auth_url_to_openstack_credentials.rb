class AddAuthUrlToOpenstackCredentials < ActiveRecord::Migration
  def self.up
    if provider_type = ProviderType.find_by_deltacloud_driver('openstack')
      CredentialDefinition.create!(:name => 'auth_url', :label => 'auth_url', :input_type => 'text', :provider_type_id => provider_type.id)
    end
  end

  def self.down
    if provider_type = ProviderType.find_by_deltacloud_driver('openstack')
      if cred = CredentialDefinition.find_by_name_and_provider_type_id('auth_url', provider_type.id)
        cred.destroy!
      end
    end
  end
end
