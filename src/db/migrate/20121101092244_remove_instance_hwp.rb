class RemoveInstanceHwp < ActiveRecord::Migration
  def up
    drop_table :instance_hwps

    remove_column :instances, :instance_hwp_id
  end

  def down
    create_table "instance_hwps", :force => true do |t|
      t.string  "memory"
      t.string  "cpu"
      t.string  "architecture"
      t.string  "storage"
      t.integer "lock_version", :default => 0
    end

    add_column :instances, :instance_hwp_id, :integer
  end
end
