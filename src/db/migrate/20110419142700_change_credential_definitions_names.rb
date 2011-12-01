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

class ChangeCredentialDefinitionsNames < ActiveRecord::Migration
  def self.up
    CredentialDefinition.all.each do |cred|
      if name_mapping.has_key? cred.label
        cred.label = name_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.down
    reverse_mapping = name_mapping.invert
    CredentialDefinition.all.each do |cred|
      if reverse_mapping.has_key? cred.label
        cred.label = reverse_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.name_mapping
    {
      "API Key" => "Access Key",
      "Secret" => "Secret Access Key",
      "AWS Account ID" => "Account Number",
      "EC2 x509 private key" => "Key",
      "EC2 x509 public key" => "Certificate",
    }
  end
end
