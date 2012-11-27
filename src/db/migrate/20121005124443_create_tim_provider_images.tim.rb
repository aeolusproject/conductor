# This migration comes from tim (originally 20120911204329)
class CreateTimProviderImages < ActiveRecord::Migration
  def change
    create_table :tim_provider_images do |t|
      t.integer :id
      t.string :factory_id
      t.integer :target_image_id
      t.string :provider
      # The Cloud Specific ID. i.e. ami-12345678
      t.string :external_image_id
      t.string :factory_provider_account_id
      t.boolean :snapshot

      t.string :status
      t.string :status_detail
      t.string :progress # Factory Target Image percent_complete
      t.timestamps
    end
  end
end
