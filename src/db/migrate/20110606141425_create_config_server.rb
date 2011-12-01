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
class CreateConfigServer < ActiveRecord::Migration
  def self.up
    create_table :config_servers do |t|
      t.string :host, :null => false
      t.string :port, :null => false
      t.string :username, :null => true
      t.string :password, :null => true
      t.string :certificate, :null => true, :limit => 2048
      t.integer :provider_account_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :config_servers
  end
end
