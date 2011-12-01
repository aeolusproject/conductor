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

class UpdateInstances < ActiveRecord::Migration
  def self.up
    change_table :instances do |t|
      t.integer :legacy_assembly_id
      t.integer :deployment_id
      t.change   :legacy_template_id, :integer, :null => true
    end

    create_table :instances_legacy_assemblies, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_deployable_id,  :null => false
    end
  end

  def self.down
    change_table :instances do |t|
      t.remove :legacy_assembly_id, :deployment_id
      t.change   :legacy_template_id, :integer, :null => false
    end
  end
end
