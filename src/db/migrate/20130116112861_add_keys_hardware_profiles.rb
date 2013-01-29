class AddKeysHardwareProfiles < ActiveRecord::Migration
  def change
    add_foreign_key "hardware_profiles", "hardware_profile_properties", :name => "hardware_profiles_architecture_id_fk", :column => "architecture_id"
    add_foreign_key "hardware_profiles", "hardware_profile_properties", :name => "hardware_profiles_cpu_id_fk", :column => "cpu_id"
    add_foreign_key "hardware_profiles", "hardware_profile_properties", :name => "hardware_profiles_memory_id_fk", :column => "memory_id"
    add_foreign_key "hardware_profiles", "providers", :name => "hardware_profiles_provider_id_fk"
    add_foreign_key "hardware_profiles", "hardware_profile_properties", :name => "hardware_profiles_storage_id_fk", :column => "storage_id"
  end
end
