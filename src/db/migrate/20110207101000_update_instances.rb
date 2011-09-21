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

class UpdateInstances < ActiveRecord::Migration
  def self.up
    change_table :instances do |t|
      t.integer :legacy_assembly_id
      t.integer :deployment_id
      t.change   :legacy_template_id, :integer, :null => true
    end

    create_table :instances_legacy_assemblies, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    change_table :instances do |t|
      t.remove :legacy_assembly_id, :deployment_id
      t.change   :legacy_template_id, :integer, :null => false
    end
  end
end
