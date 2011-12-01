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
class RemoveUrlAddXmlToCatalogEntries < ActiveRecord::Migration
  def self.up
    remove_column :catalog_entries, :url
    add_column :catalog_entries, :xml, :text
    add_column :catalog_entries, :xml_filename, :string
    execute "DELETE from catalog_entries"
  end

  def self.down
    remove_column :catalog_entries, :xml
    remove_column :catalog_entries, :xml_filename
    add_column :catalog_entries, :url, :string
    execute "DELETE from catalog_entries"
  end
end
