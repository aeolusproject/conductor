# Default Pool Family
PoolFamily.create!(:name => "default", :description => "default pool family")

# Default Pool
Pool.create!(:name => "default_pool", :quota => Quota.create, :pool_family => PoolFamily.find_by_name('default'))

# Create default privileges
privileges = ["set_perms", "view_perms",
  "instance_modify", "instance_control", "instance_view",
  "stats_view",
  "account_modify", "account_view",
  "pool_modify", "pool_view",
  "quota_modify", "quota_view",
  "provider_modify", "provider_view",
  "user_modify", "user_view",
  "image_modify", "image_view"]
Privilege.transaction do
  privileges.each do |priv_name|
    privilege = Privilege.create!(:name => priv_name)
  end
end

# Create default roles
roles = {"Instance Controller" =>
  {:role_scope => "Pool",
    :privileges => ["instance_control",
      "instance_view",
      "pool_view"]},
      "Instance Controller With Monitoring" =>
  {:role_scope => "Pool",
    :privileges => ["instance_control",
      "instance_view",
      "pool_view",
      "stats_view"]},
      "Instance Creator and User" =>
  {:role_scope => "Pool",
    :privileges => ["instance_control",
      "instance_view",
      "pool_view",
      "stats_view",
      "instance_modify",
      "quota_view",
      "set_perms",
      "view_perms"]},
      "Pool Creator" =>
  {:role_scope => "Provider",
    :privileges => ["provider_view",
      "pool_modify",
      "pool_view",
      "quota_view"]},
      "Pool Administrator" =>
  {:role_scope => "Provider",
    :privileges => ["provider_view",
      "pool_modify",
      "pool_view",
      "quota_view",
      "quota_modify",
      "set_perms",
      "view_perms"]},
      "Provider Administrator" =>
  {:role_scope => "Provider",
    :privileges => ["provider_modify",
      "provider_view",
      "account_modify",
      "account_view"]},
      "Account Administrator" =>
  {:role_scope => "CloudAccount",
    :privileges => ["set_perms",
      "view_perms",
      "stats_view",
      "account_view",
      "account_modify"]},
      "Account Viewer" =>
  {:role_scope => "CloudAccount",
    :privileges => ["account_view"]},
    "Provider Creator" =>
  {:role_scope => "BasePermissionObject",
    :privileges => ["provider_modify",
      "provider_view"]},
      "Administrator" =>
  {:role_scope => "BasePermissionObject",
    :privileges => ["provider_modify",
      "provider_view",
      "account_modify",
      "account_view",
      "user_modify",
      "user_view",
      "set_perms",
      "view_perms",
      "pool_modify",
      "pool_view",
      "quota_modify",
      "quota_view",
      "stats_view",
      "instance_modify",
      "instance_control",
      "instance_view",
      "image_modify",
      "image_view"]}

}
Role.transaction do
  roles.each do |role_name, role_hash|
    role = Role.create!(:name => role_name, :scope => role_hash[:role_scope])
    role.privileges = role_hash[:privileges].collect do |priv_name|
      Privilege.find_by_name(priv_name)
    end
    role.save!
  end
end

# General permission scope
BasePermissionObject.create!(:name => "general_permission_scope")

# Set meta objects
MetadataObject.set("default_pool_family", PoolFamily.find_by_name('default'))

default_pool = Pool.find_by_name("default_pool")
default_quota = Quota.create

default_role = Role.find_by_name("Instance Creator and User")
settings = {"allow_self_service_logins" => "true",
  "self_service_default_quota" => default_quota,
  "self_service_default_pool" => default_pool,
  "self_service_default_role" => default_role}
settings.each_pair do |key, value|
  MetadataObject.set(key, value)
end
