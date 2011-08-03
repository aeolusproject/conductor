FactoryGirl.define do

  factory :hardware_profile do
    sequence(:name) { |n| "hardware_profile#{n}" }
    sequence(:external_key) { |n| "hardware_profile_key#{n}" }
  end

  factory :mock_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:mock_hwp1_memory) }
    storage { |p| p.association(:mock_hwp1_storage) }
    cpu { |p| p.association(:mock_hwp1_cpu) }
    architecture { |p| p.association(:mock_hwp1_arch) }
    sequence(:external_key) { |n| "mock_hwp1_key#{n}" }
  end

  factory :mock_hwp2, :parent => :hardware_profile do
    memory { |p| p.association(:mock_hwp2_memory) }
    storage { |p| p.association(:mock_hwp2_storage) }
    cpu { |p| p.association(:mock_hwp2_cpu) }
    architecture { |p| p.association(:mock_hwp2_arch) }
    external_key 'mock_hwp2_key'
  end

  factory :front_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp1_memory) }
    storage { |p| p.association(:front_hwp1_storage) }
    cpu { |p| p.association(:front_hwp1_cpu) }
    architecture { |p| p.association(:front_hwp1_arch) }
    name 'front_hwp1'
    external_key 'front_hwp1_key'
  end

  factory :front_hwp2, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp2_memory) }
    storage { |p| p.association(:front_hwp2_storage) }
    cpu { |p| p.association(:front_hwp2_cpu) }
    architecture { |p| p.association(:front_hwp2_arch) }
    name 'front_hwp2'
    external_key 'front_hwp2_key'
  end


  factory :ec2_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:ec2_hwp1_memory) }
    storage { |p| p.association(:ec2_hwp1_storage) }
    cpu { |p| p.association(:ec2_hwp1_cpu) }
    architecture { |p| p.association(:ec2_hwp1_arch) }
    sequence(:external_key) { |n| "ec2_hwp1_key#{n}" }
  end

  factory :front_hwp3, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp3_memory) }
    storage { |p| p.association(:front_hwp3_storage) }
    cpu { |p| p.association(:front_hwp3_cpu) }
    architecture { |p| p.association(:front_hwp3_arch) }
    name 'front_hwp3'
    external_key 'front_hwp3_key'
  end

end
