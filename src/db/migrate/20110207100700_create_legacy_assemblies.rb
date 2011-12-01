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

class CreateLegacyAssemblies < ActiveRecord::Migration
  def self.up
    create_table :legacy_assemblies do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :architecture
      t.text    :summary
      t.boolean :uploaded, :default => false
      t.integer   :lock_version, :default => 0
      t.timestamps
    end
    create_table :legacy_assemblies_legacy_templates, :id => false do |t|
      t.integer :legacy_assembly_id,  :null => false
      t.integer :legacy_template_id,  :null => false
    end
  end

  def self.down
    drop_table :legacy_assemblies_legacy_templates
    drop_table :legacy_assemblies
  end
end
