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

class RemovePolymorphicInstanceKey < ActiveRecord::Migration
  def self.up
    remove_column :instance_keys, :instance_key_owner_type
    rename_column :instance_keys, :instance_key_owner_id, :instance_id
  end

  def self.down
    add_column :instance_keys, :instance_key_owner_type, :string
    rename_column :instance_keys, :instance_id, :instance_key_owner_id
  end
end
