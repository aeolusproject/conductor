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

class ConvertConfigServerToOauth < ActiveRecord::Migration
  def self.up
    # Why drop and recreate?
    # There's no way to undo this migration, and the safest thing to do is to
    # delete all the data in the table and start from scratch.
    # The easiest way to do that is to drop the table and recreate with the
    # correct columns.
    drop_table :config_servers
    create_table :config_servers do |t|
      t.string :endpoint, :null => false
      t.string :key, :null => false
      t.string :secret, :null => true
      t.integer :provider_account_id, :null => false

      t.timestamps
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
