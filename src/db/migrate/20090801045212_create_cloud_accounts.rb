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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class CreateCloudAccounts < ActiveRecord::Migration
  def self.up
    create_table :cloud_accounts do |t|
      t.string :label, :null => false
      t.string :username, :null => false
      t.string :password, :null => false
      t.integer :provider_id, :null => false
      t.integer :quota_id
      t.integer :lock_version, :default => 0
      t.string  :account_number, :null => false
      t.text    :x509_cert_priv, :null => false
      t.text    :x509_cert_pub, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :cloud_accounts
  end
end
