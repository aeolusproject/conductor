class RenameReplicatedImageToProviderImage < ActiveRecord::Migration
  def self.up
    rename_table :replicated_images, :legacy_provider_images
  end

  def self.down
    rename_table :legacy_provider_images, :replicated_images
  end
end
