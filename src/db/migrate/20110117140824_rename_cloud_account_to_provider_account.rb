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

class RenameCloudAccountToProviderAccount < ActiveRecord::Migration
  def self.up
    rename_table (:cloud_accounts,:provider_accounts)
    remove_column (:providers, :cloud_type)
    add_column (:providers, :provider_type, :integer)
  end

  def self.down
    remove_column (:providers, :provider_type)
    add_column (:providers, :cloud_type, :string, :null => false)
    rename_table (:provider_accounts, :cloud_accounts)
  end
end
