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

class AddProviderTypeIdToProvider < ActiveRecord::Migration

  PROVIDER_TYPES = { 0 => "Mock", 1 => "Amazon EC2", 2 => "GoGrid", 3 => "Rackspace", 4 => "RHEV-M", 5 => "OpenNebula" }
  INVERTED_PROVIDER_TYPES = PROVIDER_TYPES.invert

  def self.up
    add_column :providers, :provider_type_id, :integer, :null => false, :default => 100
    rename_column :providers, :provider_type, :provider_type_int
    transform_provider_type_column
    remove_column :providers, :provider_type_int
  end

  def self.down
    add_column :providers, :provider_type_temporary, :integer
    transform_provider_type_column_back
    rename_column :providers, :provider_type_temporary, :provider_type
    remove_column :providers, :provider_type_id
  end

  def self.transform_provider_type_column
    Provider.all.each do |provider|
      provider.update_attribute(:provider_type_id, ProviderType.first(:conditions => {:name => PROVIDER_TYPES[provider.provider_type_int]}).id)
    end
  end

  def self.transform_provider_type_column_back
    Provider.all.each do |provider|
      provider.update_attribute(:provider_type_temporary, INVERTED_PROVIDER_TYPES[provider.provider_type.name])
    end
  end
end
