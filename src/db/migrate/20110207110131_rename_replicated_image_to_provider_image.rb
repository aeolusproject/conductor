class RenameReplicatedImageToProviderImage < ActiveRecord::Migration
  def self.up
    rename_table :replicated_images, :provider_images
  end

  def self.down
    rename_table :provider_images, :replicated_images
  end
end
