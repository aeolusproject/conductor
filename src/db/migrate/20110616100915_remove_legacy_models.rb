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

class RemoveLegacyModels < ActiveRecord::Migration
  def self.up
    drop_table :instances_legacy_assemblies
    drop_table :legacy_assemblies
    drop_table :legacy_assemblies_legacy_deployables
    drop_table :legacy_assemblies_legacy_templates
    drop_table :legacy_deployables
    drop_table :legacy_images
    drop_table :legacy_provider_images
    drop_table :legacy_templates
    remove_column :deployments, :legacy_deployable_id
    remove_column :icicles, :legacy_provider_image_id
    remove_column :instances, :legacy_template_id
    remove_column :instances, :legacy_assembly_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
