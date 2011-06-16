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
