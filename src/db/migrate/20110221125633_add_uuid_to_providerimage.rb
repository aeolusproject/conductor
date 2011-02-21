class AddUuidToProviderimage < ActiveRecord::Migration
  def self.up
    add_column :provider_images, :uuid, :string
  end

  def self.down
    remove_column :provider_images, :uuid
  end
end
