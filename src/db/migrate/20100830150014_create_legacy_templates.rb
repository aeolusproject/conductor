#
# Copyright (C) 2010 Red Hat, Inc.
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

class CreateLegacyTemplates < ActiveRecord::Migration
  def self.up
    create_table :legacy_templates do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :platform
      t.string  :platform_version
      t.string  :architecture
      t.text    :summary
      t.boolean :complete, :default => false
      t.boolean :uploaded, :default => false
      t.boolean :imported, :default => false
      t.integer :legacy_images_count
      t.timestamps
    end
  end

  def self.down
    drop_table :legacy_templates
  end
end
