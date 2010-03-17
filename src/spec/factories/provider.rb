Factory.define :provider do |p|
  p.sequence(:name) { |n| "provider#{n}" }
end

Factory.define :mock_provider, :parent => :provider do |p|
  p.cloud_type 'mock'
  p.url 'http://localhost:3001/api'
  p.hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
end
