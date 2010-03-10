# FIXME need to flush out all roles w/ all privileges

Factory.define :role do |r|
end

Factory.define :admin_role, :parent => :role do |r|
  r.name 'Administrator'
  r.scope 'BasePortalObject'
  r.privileges { |p| [ p.association(:modify_pool_priv),
                       p.association(:modify_provider_priv),
                       p.association(:view_provider_priv) ] }
end

Factory.define :instance_creator, :parent => :role do |r|
  r.name 'Instance Creator and User'
  r.scope 'PortalPool'
end

Factory.define :provider_admin_role, :parent => :role do |r|
  r.name  'Provider Administrator'
  r.scope 'BasePortalObject'
  r.privileges { |p| [ p.association(:modify_provider_priv),
                       p.association(:view_provider_priv) ] }
end
