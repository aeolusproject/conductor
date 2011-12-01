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

class AddDeployables  < ActiveRecord::Migration
  def self.up
    create_table :deployables do |t|
      t.string  :name, :null => false, :limit => 1024
      t.text    :description, :null => false
      t.text    :xml
      t.string  :xml_filename
      t.integer :owner_id
    end
    add_column :catalog_entries, :deployable_id, :integer

    CatalogEntry.all.each do |entry|
      deployable = Deployable.new(:name => entry.name,
                         :description => entry.description,
                         :xml => entry.xml,
                         :xml_filename => entry.xml_filename,
                         :owner_id => entry.owner_id)
      deployable.save!
      entry.deployable = deployable
      entry.save!
    end
    remove_column :catalog_entries, :name
    remove_column :catalog_entries, :description
    remove_column :catalog_entries, :xml
    remove_column :catalog_entries, :xml_filename
    remove_column :catalog_entries, :owner_id
  end

  def self.down
    add_column :catalog_entries, :name, :string
    add_column :catalog_entries, :description, :text
    add_column :catalog_entries, :xml, :text
    add_column :catalog_entries, :xml_filename, :string
    add_column :catalog_entries, :owner_id, :integer

    Deployable.all.each do |deployable|
      entry = deployable.catalog_entries.first
      if entry
        entry.name = deployable.name
        entry.description = deployable.description
        entry.xml = deployable.xml
        entry.xml_filename = deployable.xml_filename
        entry.owner_id = deployable.owner_id
        entry.save!
      end
    end
    drop_column :catalog_entries, :deployable_id
    drop_table :deployables
  end
end
