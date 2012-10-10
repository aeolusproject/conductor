class ChangeUserGroupDescriptionTypeToString < ActiveRecord::Migration
  def up
    change_column :user_groups, :description, :text
  end

  def down
    change_column :user_groups, :description, :string
  end
end
