class CreateIcicles < ActiveRecord::Migration
  def self.up
    create_table :icicles do |t|
      t.string     :uuid
      t.text       :xml
      t.integer    :provider_image_id
      t.timestamps
    end
  end

  def self.down
    drop_table :icicles
  end
end
