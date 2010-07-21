Factory.define :pool do |p|
  p.name 'mypool'
  p.association :owner, :factory => :pool_user
end

Factory.define :tpool, :parent => :pool do |p|
  p.name 'tpool'
end
