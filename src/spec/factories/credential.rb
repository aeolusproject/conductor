#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

FactoryGirl.define do

  factory :credential do
    association :credential_definition
    sequence(:value) { |n| "value#{n}" }
  end

  # EC2 credentials
  factory :ec2_username_credential, :parent => :credential do
    value "mockuser"
    credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('ec2')})}
  end

  factory :ec2_password_credential, :parent => :credential do
    value "mockpassword"
    credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('ec2')})}
  end

  factory :ec2_account_id_credential, :parent => :credential do
    value "3141"
    credential_definition { CredentialDefinition.find_by_name('account_id',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('ec2')})}
  end

  factory :ec2_x509private_credential, :parent => :credential do
    value "x509 private key"
    credential_definition { CredentialDefinition.find_by_name('x509private',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('ec2')})}
  end

  factory :ec2_x509public_credential, :parent => :credential do
    value "x509 public key"
    credential_definition { CredentialDefinition.find_by_name('x509public',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('ec2')})}
  end

  #Mock & Others credentials
  factory :username_credential, :parent => :credential do
    value "mockuser"
    credential_definition { CredentialDefinition.find_by_name('username',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('mock')})}
  end

  factory :password_credential, :parent => :credential do
    value "mockpassword"
    credential_definition { CredentialDefinition.find_by_name('password',:conditions => {:provider_type_id => ProviderType.find_by_deltacloud_driver('mock')})}
  end

  factory :username_credential_seq, :parent => :username_credential do |ucs|
      ucs.sequence(:value) { |n| "mockuser#{n}" }
  end

  factory :password_credential_seq, :parent => :password_credential do |pcs|
      pcs.sequence(:value) { |n| "mockpassword#{n}" }
  end

end
