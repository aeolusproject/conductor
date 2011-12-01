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

class AddTargetIdColumnToLegacyImages < ActiveRecord::Migration

  PROVIDER_TYPES = { 0 => "Mock", 1 => "Amazon EC2", 2 => "GoGrid", 3 => "Rackspace", 4 => "RHEV-M", 5 => "OpenNebula" }
  INVERTED_PROVIDER_TYPES = PROVIDER_TYPES.invert

  def self.up
    add_column :legacy_images, :provider_type_id, :integer, :null => false, :default => 100
    remove_column :legacy_images, :target  end

  def self.down
    add_column :legacy_images, :target, :integer
    remove_column :legacy_images, :provider_type_id
  end
end
