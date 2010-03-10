Factory.define :privilege do |p|
end

Factory.define :modify_pool_priv, :parent => :privilege do |p|
  p.name 'pool_modify'
end

Factory.define :modify_provider_priv, :parent => :privilege do |p|
  p.name 'provider_modify'
end

Factory.define :view_provider_priv, :parent => :privilege do |p|
  p.name 'provider_view'
end
