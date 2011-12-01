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
