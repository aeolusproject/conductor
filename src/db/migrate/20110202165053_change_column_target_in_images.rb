class ChangeColumnTargetInImages < ActiveRecord::Migration
  def self.up
    remove_column :images, :target
    add_column :images, :target, :integer
  end

  def self.down
    remove_column :images, :target
    add_column :images, :target, :string
  end
end
