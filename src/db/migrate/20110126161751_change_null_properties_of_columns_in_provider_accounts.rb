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

class ChangeNullPropertiesOfColumnsInProviderAccounts < ActiveRecord::Migration
  def self.up
    change_column :provider_accounts, :account_number, :string, :null => true
    change_column :provider_accounts, :x509_cert_priv, :text, :null => true
    change_column :provider_accounts, :x509_cert_pub, :text, :null => true
  end

  def self.down
    change_column :provider_accounts, :account_number, :string, :null => false
    change_column :provider_accounts, :x509_cert_priv, :text, :null => false
    change_column :provider_accounts, :x509_cert_pub, :text, :null => false
  end
end
