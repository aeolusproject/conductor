FactoryGirl.define do

  factory :property_enum_entry do
  end

  factory :mock_hwp2_storage_enum1, :parent => :property_enum_entry do
    value 850
    hardware_profile_property { |e| e.association(:mock_hwp2_storage) }
  end

  factory :mock_hwp2_storage_enum2, :parent => :property_enum_entry do
    value 1024
    hardware_profile_property { |e| e.association(:mock_hwp2_storage) }
  end

  factory :agg_hwp2_storage_enum1, :parent => :property_enum_entry do
    value 850
    hardware_profile_property { |e| e.association(:agg_hwp2_storage) }
  end

  factory :agg_hwp2_storage_enum2, :parent => :property_enum_entry do
    value 1024
    hardware_profile_property { |e| e.association(:agg_hwp2_storage) }
  end

end
