class ChangeCredentialDefinitions < ActiveRecord::Migration
  def self.up
    transform_credential_definitions
  end

  def self.down
    transform_credential_definitions_back
  end

  def self.transform_credential_definitions
    ec2 = ProviderType.find_by_codename('ec2')
    CredentialDefinition.all.each do |cred|
      if cred.provider_type != ec2
        if cred.name == 'username'
          cred.update_attribute(:label, 'Username')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Password')
        end
      else
        if cred.name == 'username'
          cred.update_attribute(:label, 'API Key')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Secret')
        end
      end
    end
  end

  def self.transform_credential_definitions_back
    ec2 = ProviderType.find_by_codename('ec2')
    CredentialDefinition.all.each do |cred|
      if cred.provider_type != ec2
        if cred.name == 'username'
          cred.update_attribute(:label, 'API Key')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Secret')
        end
      else
        if cred.name == 'username'
          cred.update_attribute(:label, 'Username')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Password')
        end
      end
    end
  end

end
