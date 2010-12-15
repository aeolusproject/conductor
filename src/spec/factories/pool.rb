Factory.define :pool do |p|
  p.sequence(:name) { |n| "mypool#{n}" }
  p.association :zone, :factory => :zone
  p.association :quota
end

Factory.define :tpool, :parent => :pool do |p|
  p.name 'tpool'
end
