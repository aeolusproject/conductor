Factory.define :provider do |p|
end

Factory.define :mock1, :parent => :provider do |p|
  p.name 'mock1'
  p.cloud_type 'mock'
  p.url 'http://localhost:3001/api'
end
