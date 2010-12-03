Factory.define :hardware_profile do |p|
  p.sequence(:name) { |n| "hardware_profile#{n}" }
  p.sequence(:external_key) { |n| "hardware_profile_key#{n}" }
end

Factory.define :mock_hwp1, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:mock_hwp1_memory) }
  p.storage { |p| p.association(:mock_hwp1_storage) }
  p.cpu { |p| p.association(:mock_hwp1_cpu) }
  p.architecture { |p| p.association(:mock_hwp1_arch) }
  p.sequence(:external_key) { |n| "mock_hwp1_key#{n}" }
end

Factory.define :mock_hwp2, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:mock_hwp2_memory) }
  p.storage { |p| p.association(:mock_hwp2_storage) }
  p.cpu { |p| p.association(:mock_hwp2_cpu) }
  p.architecture { |p| p.association(:mock_hwp2_arch) }
  p.external_key 'mock_hwp2_key'
end

Factory.define :agg_hwp1, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:agg_hwp1_memory) }
  p.storage { |p| p.association(:agg_hwp1_storage) }
  p.cpu { |p| p.association(:agg_hwp1_cpu) }
  p.architecture { |p| p.association(:agg_hwp1_arch) }
  p.provider_hardware_profiles { |hp| [hp.association(:mock_hwp1)] }
  p.external_key 'agg_hwp1_key'
end

Factory.define :agg_hwp2, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:agg_hwp2_memory) }
  p.storage { |p| p.association(:agg_hwp2_storage) }
  p.cpu { |p| p.association(:agg_hwp2_cpu) }
  p.architecture { |p| p.association(:agg_hwp2_arch) }
  p.provider_hardware_profiles { |hp| [hp.association(:mock_hwp2)] }
  p.external_key 'agg_hwp2_key'
end


Factory.define :ec2_hwp1, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:ec2_hwp1_memory) }
  p.storage { |p| p.association(:ec2_hwp1_storage) }
  p.cpu { |p| p.association(:ec2_hwp1_cpu) }
  p.architecture { |p| p.association(:ec2_hwp1_arch) }
  p.sequence(:external_key) { |n| "ec2_hwp1_key#{n}" }
end

Factory.define :agg_hwp3, :parent => :hardware_profile do |p|
  p.memory { |p| p.association(:agg_hwp3_memory) }
  p.storage { |p| p.association(:agg_hwp3_storage) }
  p.cpu { |p| p.association(:agg_hwp3_cpu) }
  p.architecture { |p| p.association(:agg_hwp3_arch) }
  p.provider_hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
  p.external_key 'agg_hwp3_key'
end
