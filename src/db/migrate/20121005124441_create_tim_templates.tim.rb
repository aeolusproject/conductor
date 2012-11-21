# This migration comes from tim (originally 20120910175233)
class CreateTimTemplates < ActiveRecord::Migration
  def change
    create_table :tim_templates do |t|
      t.text :xml

      t.timestamps
    end
  end
end
