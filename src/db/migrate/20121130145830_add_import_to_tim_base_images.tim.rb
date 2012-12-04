# This migration comes from tim (originally 20121115151914)
class AddImportToTimBaseImages < ActiveRecord::Migration
  def change
    add_column :tim_base_images, :import, :boolean, :default => false
  end
end
