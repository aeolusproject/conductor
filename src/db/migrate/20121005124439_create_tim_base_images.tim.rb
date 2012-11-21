# This migration comes from tim (originally 20120906180351)
class CreateTimBaseImages < ActiveRecord::Migration
  def change
    create_table :tim_base_images do |t|
      t.string :name
      t.string :description
      t.integer :template_id
      t.integer :user_id

      t.timestamps
    end
  end
end
