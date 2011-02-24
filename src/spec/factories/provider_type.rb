Factory.define :provider_type do |p|
end

Factory.define :mock_provider_type, :parent => :provider_type do |p|
  p.name 'Mock'
end

Factory.define :ec2_provider_type, :parent => :provider_type do |p|
  p.name 'Amazon EC2'
end
