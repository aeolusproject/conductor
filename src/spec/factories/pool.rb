Factory.define :pool do |p|
  p.sequence(:name) { |n| "mypool#{n}" }
  p.pool_family { |p| PoolFamily.find_by_name('default') }
  p.association :quota
  p.enabled true
end

Factory.define :tpool, :parent => :pool do |p|
  p.name 'tpool'
end

Factory.define :disabled_pool, :parent => :pool do |p|
  p.enabled false
end
