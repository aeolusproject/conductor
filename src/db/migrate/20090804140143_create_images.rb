#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string  :uuid
      t.string  :name, :null => false
      t.string  :build_id
      t.string  :uri
      t.string  :status
      t.string  :target
      t.integer :template_id
      t.timestamps
    end

    create_table :replicated_images do |t|
      t.integer :image_id, :null => false
      t.integer :provider_id, :null => false
      t.string  :provider_image_key
      t.boolean :uploaded, :default => false
      t.boolean :registered, :default => false
    end
  end

  def self.down
    drop_table :replicated_images
    drop_table :images
  end
end
