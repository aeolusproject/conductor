class AddProviderAccountIdToTimProviderImage < ActiveRecord::Migration
  def change
    add_column :tim_provider_images, :provider_account_id, :integer
  end
end
