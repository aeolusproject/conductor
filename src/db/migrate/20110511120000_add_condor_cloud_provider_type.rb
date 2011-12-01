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
