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
class UpdatePasswordAttrs < ActiveRecord::Migration
  def self.up
    remove_column :users, :password_salt
    remove_column :users, :persistence_token
    remove_column :users, :single_access_token
    remove_column :users, :perishable_token
  end

  def self.down
    add_column :users, :password_salt, :string
    add_column :users, :persistence_token, :string
    add_column :users, :single_access_token, :string
    add_column :users, :perishable_token, :string
  end
end
