Factory.define :hardware_profile_property do |p|
end

Factory.define :mock_hwp1_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 1740.8
end

Factory.define :mock_hwp1_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'fixed'
  p.unit 'GB'
  p.value 160
end

Factory.define :mock_hwp1_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 1.0
end

Factory.define :mock_hwp1_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'i386'
end

Factory.define :mock_hwp2_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'range'
  p.unit 'MB'
  p.value 10240
  p.range_first 7680
  p.range_last 15360
end

Factory.define :mock_hwp2_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'enum'
  p.unit 'GB'
  p.value 850
#  p.property_enum_entries { |p| [p.association(:mock_hwp2_storage_enum1),
#                                p.association(:mock_hwp2_storage_enum2)] }
end

Factory.define :mock_hwp2_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 2.0
end

Factory.define :mock_hwp2_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'x86_64'
end

Factory.define :front_hwp1_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 1
end

Factory.define :front_hwp1_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'fixed'
  p.unit 'GB'
  p.value 1
end

Factory.define :front_hwp1_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 1
end

Factory.define :front_hwp1_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'x86_64'
end

Factory.define :front_hwp2_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 1024
end

Factory.define :front_hwp2_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'fixed'
  p.unit 'GB'
  p.value 2
end

Factory.define :front_hwp2_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 1
end

Factory.define :front_hwp2_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'x86_64'
end


# EC2 Profiles:


Factory.define :ec2_hwp1_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 1740.8
end

Factory.define :ec2_hwp1_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'fixed'
  p.unit 'GB'
  p.value 160
end

Factory.define :ec2_hwp1_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 1.0
end

Factory.define :ec2_hwp1_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'i386'
end

Factory.define :front_hwp3_memory, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 1740.8
end

Factory.define :front_hwp3_storage, :parent => :hardware_profile_property do |p|
  p.name 'storage'
  p.kind 'fixed'
  p.unit 'GB'
  p.value 3
end

Factory.define :front_hwp3_cpu, :parent => :hardware_profile_property do |p|
  p.name 'cpu'
  p.kind 'fixed'
  p.unit 'count'
  p.value 1
end

Factory.define :front_hwp3_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'i386'
end

Factory.define :hwpp_range, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'range'
  p.unit 'MB'
  p.range_first 256
  p.range_last 512
  p.value 256
end

Factory.define :hwpp_fixed, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'fixed'
  p.unit 'MB'
  p.value 256
end

Factory.define :hwpp_enum, :parent => :hardware_profile_property do |p|
  p.name 'memory'
  p.kind 'enum'
  p.unit 'MB'
  p.value 256
end

Factory.define :hwpp_arch, :parent => :hardware_profile_property do |p|
  p.name 'architecture'
  p.kind 'fixed'
  p.unit 'label'
  p.value 'i386'
end
