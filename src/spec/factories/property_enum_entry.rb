Factory.define :property_enum_entry do |e|
end

Factory.define :mock_hwp2_storage_enum1, :parent => :property_enum_entry do |e|
  e.value 850
  e.hardware_profile_property { |e| e.association(:mock_hwp2_storage) }
end

Factory.define :mock_hwp2_storage_enum2, :parent => :property_enum_entry do |e|
  e.value 1024
  e.hardware_profile_property { |e| e.association(:mock_hwp2_storage) }
end

Factory.define :agg_hwp2_storage_enum1, :parent => :property_enum_entry do |e|
  e.value 850
  e.hardware_profile_property { |e| e.association(:agg_hwp2_storage) }
end

Factory.define :agg_hwp2_storage_enum2, :parent => :property_enum_entry do |e|
  e.value 1024
  e.hardware_profile_property { |e| e.association(:agg_hwp2_storage) }
end
