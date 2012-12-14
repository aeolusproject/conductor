class ChangeFrontendRealmsDescriptionTypeToString < ActiveRecord::Migration
  def up
    change_column :frontend_realms, :description, :text

  end

  def down
    change_column :frontend_realms, :description, :text
  end
end
