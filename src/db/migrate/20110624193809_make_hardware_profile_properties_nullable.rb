class MakeHardwareProfilePropertiesNullable < ActiveRecord::Migration
  def self.up
    change_column :hardware_profile_properties, :value, :string, :null => true
  end

  def self.down
    change_column :hardware_profile_properties, :value, :string, :null => false
  end
end
