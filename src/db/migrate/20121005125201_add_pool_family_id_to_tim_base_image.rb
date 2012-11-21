class AddPoolFamilyIdToTimBaseImage < ActiveRecord::Migration
  def change
    add_column :tim_base_images, :pool_family_id, :integer
  end
end
