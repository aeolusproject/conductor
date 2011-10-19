module HardwareProfilesHelper
  def hardware_profiles_header
    [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("hardware_profiles.index.hardware_profile_name"), :sort_attr => :name },
      { :name => t("hardware_profiles.index.architecture"), :sort_attr => :architecture },
      { :name => t("hardware_profiles.index.memory"), :class => 'center', :sort_attr => :memory},
      { :name => t("hardware_profiles.index.storage"), :class => 'center', :sort_attr => :storage },
      { :name => t("hardware_profiles.index.virtual_cpu"), :class => 'center', :sort_attr => :cpu}
    ]
  end
end
