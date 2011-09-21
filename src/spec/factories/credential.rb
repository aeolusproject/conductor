#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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

end
