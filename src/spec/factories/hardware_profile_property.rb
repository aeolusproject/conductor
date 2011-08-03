FactoryGirl.define do

  factory :hardware_profile_property do
  end

  factory :mock_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :mock_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 160
  end

  factory :mock_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1.0
  end

  factory :mock_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :mock_hwp2_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'range'
    unit 'MB'
    value 10240
    range_first 7680
    range_last 15360
  end

  factory :mock_hwp2_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'enum'
    unit 'GB'
    value 850
  #  p.property_enum_entries { |p| [p.association(:mock_hwp2_storage_enum1),
  #                                association(:mock_hwp2_storage_enum2)] }
  end

  factory :mock_hwp2_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 2.0
  end

  factory :mock_hwp2_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1
  end

  factory :front_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 1
  end

  factory :front_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp2_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1024
  end

  factory :front_hwp2_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 2
  end

  factory :front_hwp2_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp2_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end


  # EC2 Profiles:


  factory :ec2_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :ec2_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 160
  end

  factory :ec2_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1.0
  end

  factory :ec2_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp3_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :front_hwp3_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 3
  end

  factory :front_hwp3_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp3_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :hwpp_range, :parent => :hardware_profile_property do
    name 'memory'
    kind 'range'
    unit 'MB'
    range_first 256
    range_last 512
    value 256
  end

  factory :hwpp_fixed, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 256
  end

  factory :hwpp_enum, :parent => :hardware_profile_property do
    name 'memory'
    kind 'enum'
    unit 'MB'
    value 256
  end

  factory :hwpp_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

end
