class FixInstanceHwps < ActiveRecord::Migration
  def up
    add_column :instance_hwps, :hardware_profile_id, :integer
  end

  def down
    remove_column :instance_hwps, :hardware_profile_id
  end
end
