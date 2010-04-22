Factory.define :hardware_profile do |p|
  p.sequence(:name) { |n| "hardware_profile#{n}" }
end

Factory.define :mock_hwp1, :parent => :hardware_profile do |p|
  p.memory 1024
  p.storage 100
  p.external_key 'mock_hwp1_key'
  p.architecture 'i686'
end

Factory.define :mock_hwp2, :parent => :hardware_profile do |p|
  p.memory 2048
  p.storage 400
  p.external_key 'mock_hwp2_key'
  p.architecture 'x86_64'
end

Factory.define :pool_hwp1, :parent => :hardware_profile do |p|
  p.memory 2048
  p.storage 400
  p.external_key 'pool_hwp1_key'
  p.architecture 'x86_64'
end

Factory.define :hardware_profile_auto, :parent => :hardware_profile do |p|
  p.external_key { |hp| hp.name + "_key" }
  p.storage 160
  p.memory 1024
  p.architecture "i386"
end