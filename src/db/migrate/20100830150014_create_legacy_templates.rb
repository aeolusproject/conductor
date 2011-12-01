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

class CreateLegacyTemplates < ActiveRecord::Migration
  def self.up
    create_table :legacy_templates do |t|
      t.string  :uuid, :null => false
      t.binary  :xml, :null => false
      t.string  :uri
      t.string  :name
      t.string  :platform
      t.string  :platform_version
      t.string  :architecture
      t.text    :summary
      t.boolean :complete, :default => false
      t.boolean :uploaded, :default => false
      t.boolean :imported, :default => false
      t.integer :legacy_images_count
      t.timestamps
    end
  end

  def self.down
    drop_table :legacy_templates
  end
end
