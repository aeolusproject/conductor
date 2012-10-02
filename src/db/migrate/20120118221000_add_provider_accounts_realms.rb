#
#   Copyright 2012 Red Hat, Inc.
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

class AddProviderAccountsRealms < ActiveRecord::Migration
  class Realm < ActiveRecord::Base
  end

  def self.up
    unless ActiveRecord::Base.connection.tables.include?('provider_accounts_realms')
      create_table :provider_accounts_realms, :id => false do |t|
        t.integer :provider_account_id, :null => false
        t.integer :realm_id,          :null => false
      end
    end

    Realm.transaction do
      Realm.all.each do |realm|
        realm.provider_accounts << realm.provider.provider_accounts
        realm.save!
      end
    end
  end

  def self.down
    drop_table :provider_accounts_realms
  end
end
