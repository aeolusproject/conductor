class ChangeColumnTargetInLegacyImages < ActiveRecord::Migration
  def self.up
    remove_column :legacy_images, :target
    add_column :legacy_images, :target, :integer
  end

  def self.down
    remove_column :legacy_images, :target
    add_column :legacy_images, :target, :string
  end
end
