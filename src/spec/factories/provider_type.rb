Factory.define :provider_type do |p|
  p.sequence(:name) { |n| "name#{n}" }
  p.sequence(:codename) { |n| "codename#{n}" }
end

Factory.define :mock_provider_type, :parent => :provider_type do |p|
  p.name 'Mock'
  p.codename 'mock'
end

Factory.define :ec2_provider_type, :parent => :provider_type do |p|
  p.name 'Amazon EC2'
  p.codename 'ec2'
end
