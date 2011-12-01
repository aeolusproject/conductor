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

class AddStatusToProviderImage < ActiveRecord::Migration
  def self.up
    add_column :legacy_provider_images, :status, :string
    remove_column :legacy_provider_images, :uploaded
    remove_column :legacy_provider_images, :registered
  end

  def self.down
    add_column :legacy_provider_images, :uploaded, :boolean
    add_column :legacy_provider_images, :registered, :boolean
    remove_column :legacy_provider_images, :status
  end
end
