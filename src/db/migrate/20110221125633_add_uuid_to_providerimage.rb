class AddUuidToProviderimage < ActiveRecord::Migration
  def self.up
    add_column :legacy_provider_images, :uuid, :string
  end

  def self.down
    remove_column :legacy_provider_images, :uuid
  end
end
