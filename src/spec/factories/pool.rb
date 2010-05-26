Factory.define :pool do |p|
  p.name 'mypool'
  p.owner { |owner| owner.association(:user, :login => 'pool_owner', :email => 'pool_owner@example.com') }
end

Factory.define :tpool, :parent => :pool do |p|
  p.name 'tpool'
end
