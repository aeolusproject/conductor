Factory.define :credential do |c|
  c.association :credential_definition
  c.sequence(:value) {|n| "value#{n}"}
end

# EC2 credentials
Factory.define :ec2_username_credential, :parent => :credential do |c|
  c.value "mockuser"
  c.credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
end

Factory.define :ec2_password_credential, :parent => :credential do |c|
  c.value "mockpassword"
  c.credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
end

Factory.define :ec2_account_id_credential, :parent => :credential do |c|
  c.value "3141"
  c.credential_definition { CredentialDefinition.find_by_name('account_id',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
end

Factory.define :ec2_x509private_credential, :parent => :credential do |c|
  c.value "x509 private key"
  c.credential_definition { CredentialDefinition.find_by_name('x509private',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
end

Factory.define :ec2_x509public_credential, :parent => :credential do |c|
  c.value "x509 public key"
  c.credential_definition { CredentialDefinition.find_by_name('x509public',:conditions => {:provider_type_id => ProviderType.find_by_codename('ec2')})}
end

#Mock & Others credentials
Factory.define :username_credential, :parent => :credential do |c|
  c.value "mockuser"
  c.credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_codename('mock')})}
end

Factory.define :password_credential, :parent => :credential do |c|
  c.value "mockpassword"
  c.credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_codename('mock')})}
end
