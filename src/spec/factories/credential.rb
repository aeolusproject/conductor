FactoryGirl.define do

  factory :credential do
    association :credential_definition
    sequence(:value) { |n| "value#{n}" }
  end

  # EC2 credentials
  factory :ec2_username_credential, :parent => :credential do
    value "mockuser"
    credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
  end

  factory :ec2_password_credential, :parent => :credential do
    value "mockpassword"
    credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
  end

  factory :ec2_account_id_credential, :parent => :credential do
    value "3141"
    credential_definition { CredentialDefinition.find_by_name('account_id',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
  end

  factory :ec2_x509private_credential, :parent => :credential do
    value "x509 private key"
    credential_definition { CredentialDefinition.find_by_name('x509private',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
  end

  factory :ec2_x509public_credential, :parent => :credential do
    value "x509 public key"
    credential_definition { CredentialDefinition.find_by_name('x509public',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
  end

  #Mock & Others credentials
  factory :username_credential, :parent => :credential do
    value "mockuser"
    credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_codename('mock')})}
  end

  factory :password_credential, :parent => :credential do
    value "mockpassword"
    credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_codename('mock')})}
  end

end
