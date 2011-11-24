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
