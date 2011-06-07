class UpdateInstanceToNewIwhd < ActiveRecord::Migration
  def self.up
    add_column :instances, :assembly_xml, :text
    add_column :instances, :image_uuid, :string
    add_column :instances, :image_build_uuid, :string
    add_column :instances, :provider_image_uuid, :string
  end

  def self.down
    drop_column :instances, :provider_image_uuid
    drop_column :instances, :image_build_uuid
    drop_column :instances, :image_uuid
    drop_column :instances, :assembly_xml
  end
end
