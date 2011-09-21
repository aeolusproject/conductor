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

class UpdateDeployables < ActiveRecord::Migration
  def self.up
    change_table :legacy_deployables do |t|
      t.integer :lock_version, :default => 0
      t.string  :uuid
      t.binary  :xml
      t.string  :uri
      t.text    :summary
      t.boolean :uploaded, :default => false
    end

    change_column :legacy_deployables, :uuid, :string, :null => false
    change_column :legacy_deployables, :xml, :string, :null => false

    create_table :legacy_assemblies_legacy_deployables, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    drop_table :legacy_assemblies_legacy_deployables
    change_table :legacy_deployables do |t|
      t.remove  :lock_version, :uuid, :xml, :uri, :summary, :uploaded
    end
  end
end
