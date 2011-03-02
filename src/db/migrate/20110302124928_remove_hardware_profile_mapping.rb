class RemoveHardwareProfileMapping < ActiveRecord::Migration
  def self.up
    drop_table :hardware_profile_map
  end

  def self.down
    create_table "hardware_profile_map", :force => true, :id => false do |t|
      t.column "conductor_hardware_profile_id", :integer
      t.column "provider_hardware_profile_id", :integer
    end
  end
end
