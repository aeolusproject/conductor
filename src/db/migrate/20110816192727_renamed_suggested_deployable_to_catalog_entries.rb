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

class RenamedSuggestedDeployableToCatalogEntries < ActiveRecord::Migration
  def self.up
    rename_table :suggested_deployables, :catalog_entries
    add_column :catalog_entries, :catalog_id, :integer
    change_column :catalog_entries, :catalog_id, :integer, :null => false
  end

  def self.down
    rename_table :catalog_entries, :suggested_deployables
    drop_column :catalog_id
  end
end
