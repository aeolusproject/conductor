# This migration comes from tim (originally 20121210131423)
class AddBuildMethodToTargetImage < ActiveRecord::Migration
  def change
    add_column :tim_target_images, :build_method, :string, :default => "BARE_METAL"
  end
end
