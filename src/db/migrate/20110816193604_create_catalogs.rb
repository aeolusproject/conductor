class CreateCatalogs < ActiveRecord::Migration
  def self.up
    create_table :catalogs do |t|
      t.integer :pool_id
      t.string  :name
      t.timestamps
    end
  end

  def self.down
    drop_table :catalogs
  end
end
