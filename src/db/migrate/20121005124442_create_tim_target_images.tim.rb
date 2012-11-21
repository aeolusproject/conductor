# This migration comes from tim (originally 20120911202321)
class CreateTimTargetImages < ActiveRecord::Migration
  def change
    create_table :tim_target_images do |t|
      t.string :factory_id
      t.integer :image_version_id
      t.string :target
      t.string :status
      t.string :status_detail
      t.string :progress # Factory Target Image percent_complete

      t.timestamps
    end
  end
end
