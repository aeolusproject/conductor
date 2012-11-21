# This migration comes from tim (originally 20120906210106)
class CreateTimImageVersions < ActiveRecord::Migration
  def change
    create_table :tim_image_versions do |t|
      t.integer :base_image_id
      t.integer :template_id

      t.timestamps
    end
  end
end
