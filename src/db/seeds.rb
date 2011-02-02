# Default Pool Family
PoolFamily.create!(:name => "default", :description => "default pool family")

# Default Pool
Pool.create!(:name => "default_pool", :quota => Quota.create, :pool_family => PoolFamily.find_by_name('default'))


# Create default roles
VIEW = "view"
USE  = "use"
MOD  = "modify"
CRE  = "create"
VPRM = "view_perms"
GPRM = "set_perms"

roles =
  {Instance =>
     {"Instance Controller"    => [false, {Instance     => [VIEW,USE]}],
      "Instance Owner"         => [true,  {Instance     => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   PoolFamily =>
     {"Pool Family User"       => [false, {Pool         => [VIEW]}],
      "Pool Family Owner"      => [true,  {PoolFamily   => [VIEW,    MOD,    VPRM,GPRM],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM]}]},
   Pool =>
     {"Pool User"              => [false, {Pool         => [VIEW],
                                           Instance     => [             CRE],
                                           Quota        => [VIEW]}],
      "Pool Owner"             => [true,  {Pool         => [VIEW,    MOD,    VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE],
                                           Quota        => [VIEW]}]},
   Provider =>
     {"Provider Owner"         => [true,  {Provider     => [VIEW,    MOD,    VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}]},
   ProviderAccount =>
     {"Provider Account User"  => [false, {ProviderAccount => [VIEW,USE]}],
      "Provider Account Owner" => [true,  {ProviderAccount => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Template =>
     {"Template User"          => [false, {Template     => [VIEW,USE]}],
      "Template Owner"         => [true,  {Template     => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   BasePermissionObject =>
     {"Provider Creator"       => [false, {Provider     => [             CRE]}],
      "Provider Administrator" => [false, {Provider     => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "HWP Administrator"      => [false, {HardwareProfile => [      MOD,CRE,VPRM,GPRM]}],
      "Realm Administrator"    => [false, {Realm        => [     USE,MOD,CRE,VPRM,GPRM]}],
      "Pool Creator"           => [false, {Pool         => [             CRE]}],
      "Pool Administrator"     => [false, {Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM]}],
      "Template Administrator" => [false, {Template     => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Administrator"          => [false, {Provider     => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           HardwareProfile => [      MOD,CRE,VPRM,GPRM],
                                           Realm        => [     USE,MOD,CRE,VPRM,GPRM],
                                           User         => [VIEW,    MOD,CRE],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Template     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           BasePermissionObject => [ MOD,    VPRM,GPRM]}]}}
Role.transaction do
  roles.each do |role_scope, scoped_hash|
    scoped_hash.each do |role_name, role_def|
      role_def[1].each do |priv_type, priv_actions|
        role = Role.find_or_initialize_by_name(role_name)
        role.update_attributes({:name => role_name, :scope => role_scope.name,
                                 :assign_to_owner => role_def[0]})
        role.save!
        priv_actions.each do |action|
          Privilege.create!(:role => role, :target_type => priv_type.name,
                            :action => action)
        end
      end
    end
  end
end

# General permission scope
BasePermissionObject.create!(:name => "general_permission_scope")

# Set meta objects
MetadataObject.set("default_pool_family", PoolFamily.find_by_name('default'))

default_pool = Pool.find_by_name("default_pool")
default_quota = Quota.create

default_role = Role.find_by_name("Pool User")
settings = {"allow_self_service_logins" => "true",
  "self_service_default_quota" => default_quota,
  "self_service_default_pool" => default_pool,
  "self_service_default_role" => default_role}
settings.each_pair do |key, value|
  MetadataObject.set(key, value)
end
