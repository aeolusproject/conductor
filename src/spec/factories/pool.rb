Factory.define :pool do |p|
  p.sequence(:name) { |n| "mypool#{n}" }
  p.association :pool_family, :factory => :pool_family
  p.association :quota
end

Factory.define :tpool, :parent => :pool do |p|
  p.name 'tpool'
end
