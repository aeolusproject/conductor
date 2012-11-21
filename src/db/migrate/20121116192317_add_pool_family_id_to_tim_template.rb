class AddPoolFamilyIdToTimTemplate < ActiveRecord::Migration
  def change
    add_column :tim_templates, :pool_family_id, :integer
  end
end
