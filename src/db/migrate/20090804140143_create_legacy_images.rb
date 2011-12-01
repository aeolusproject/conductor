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

class CreateLegacyImages < ActiveRecord::Migration
  def self.up
    create_table :legacy_images do |t|
      t.string  :uuid
      t.string  :name, :null => false
      t.string  :build_id
      t.string  :uri
      t.string  :status
      t.string  :target
      t.integer :legacy_template_id
      t.timestamps
    end

    create_table :replicated_images do |t|
      t.integer :legacy_image_id, :null => false
      t.integer :provider_id, :null => false
      t.string  :provider_image_key
      t.boolean :uploaded, :default => false
      t.boolean :registered, :default => false
    end
  end

  def self.down
    drop_table :replicated_images
    drop_table :legacy_images
  end
end
