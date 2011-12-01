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

class UpdateDeployables < ActiveRecord::Migration
  def self.up
    change_table :legacy_deployables do |t|
      t.integer :lock_version, :default => 0
      t.string  :uuid
      t.binary  :xml
      t.string  :uri
      t.text    :summary
      t.boolean :uploaded, :default => false
    end

    change_column :legacy_deployables, :uuid, :string, :null => false
    change_column :legacy_deployables, :xml, :string, :null => false

    create_table :legacy_assemblies_legacy_deployables, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    drop_table :legacy_assemblies_legacy_deployables
    change_table :legacy_deployables do |t|
      t.remove  :lock_version, :uuid, :xml, :uri, :summary, :uploaded
    end
  end
end
