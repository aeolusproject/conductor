Factory.define :portal_pool do |p|
  p.name 'mypool'
  p.owner { |owner| owner.association(:user, :login => 'pool_owner', :email => 'pool_owner@example.com') }
end

Factory.define :tpool, :parent => :portal_pool do |p|
  p.name 'tpool'
  p.hardware_profiles { |hp| [hp.association(:pool_hwp1)] }
end
