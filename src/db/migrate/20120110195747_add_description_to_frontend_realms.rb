class AddDescriptionToFrontendRealms < ActiveRecord::Migration
  def self.up
    add_column :frontend_realms, :description, :string
  end

  def self.down
    remove_column :frontend_realms, :description
  end
end
