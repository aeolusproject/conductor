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
