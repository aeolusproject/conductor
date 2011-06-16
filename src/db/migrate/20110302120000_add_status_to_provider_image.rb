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
