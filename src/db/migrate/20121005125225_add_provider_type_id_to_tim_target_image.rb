class AddProviderTypeIdToTimTargetImage < ActiveRecord::Migration
  def change
    add_column :tim_target_images, :provider_type_id, :integer
  end
end
