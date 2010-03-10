Factory.define :permission do |p|
end

Factory.define :admin_permission, :parent => :permission do |p|
  p.role { |r| r.association(:admin_role) }
  p.permission_object { |r| r.association(:base_portal_object) }
  p.user { |r| r.association(:admin_user) }
end

Factory.define :provider_admin_permission, :parent => :permission do |p|
  p.role { |r| r.association(:provider_admin_role) }
  p.permission_object { |r| r.association(:mock1) }
  p.user { |r| r.association(:provider_admin_user) }
end
