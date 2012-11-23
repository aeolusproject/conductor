class AddUuidToBaseImageAndImageVersion < ActiveRecord::Migration
  def change
    add_column :tim_base_images, :uuid, :string
    add_column :tim_image_versions, :uuid, :string
  end
end
