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

class UpdateInstanceToNewIwhd < ActiveRecord::Migration
  def self.up
    add_column :instances, :assembly_xml, :text
    add_column :instances, :image_uuid, :string
    add_column :instances, :image_build_uuid, :string
    add_column :instances, :provider_image_uuid, :string
  end

  def self.down
    drop_column :instances, :provider_image_uuid
    drop_column :instances, :image_build_uuid
    drop_column :instances, :image_uuid
    drop_column :instances, :assembly_xml
  end
end
