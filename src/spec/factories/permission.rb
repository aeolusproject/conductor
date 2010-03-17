Factory.define :permission do |p|
  p.after_build { |p| p.user.permissions << p }
end

Factory.define :admin_permission, :parent => :permission do |p|
  p.role { |r| Role.find(:first, :conditions => ['name = ?', 'Administrator']) }
  p.permission_object { |r| BasePortalObject.general_permission_scope }
  p.user { |u| u.association(:admin_user) }
end

Factory.define :provider_admin_permission, :parent => :permission do |p|
  p.role { |r| Role.find(:first, :conditions => ['name = ?', 'Provider Administrator']) }
  p.permission_object { |r| r.association(:mock_provider) }
  p.user { |u| u.association(:provider_admin_user) }
end

Factory.define :pool_creator_permission, :parent => :permission do |p|
  p.role { |r| Role.find(:first, :conditions => ['name = ?', 'Pool Creator']) }
  p.permission_object { |r| r.association(:mock_provider) }
  p.user { |u| u.association(:pool_creator) }
end
