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
   Deployment =>
     {"Deployment Controller"  => [false, {Deployment => [VIEW,USE],
                                           Instance   => [VIEW]}],
      "Deployment Owner"       => [true,  {Deployment => [VIEW,USE,MOD,    VPRM,GPRM],
                                           Instance   => [VIEW,USE,MOD]}]},
   PoolFamily =>
     {"Pool Family User"       => [false, {Pool         => [VIEW]}],
      "Pool Family Owner"      => [true,  {PoolFamily   => [VIEW,    MOD,    VPRM,GPRM],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM]}]},
   Pool =>
     {"Pool User"              => [false, {Pool         => [VIEW],
                                           Instance     => [             CRE],
                                           Deployment   => [             CRE],
                                           Quota        => [VIEW]}],
      "Pool Owner"             => [true,  {Pool         => [VIEW,    MOD,    VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE],
                                           Deployment   => [VIEW,USE,MOD,CRE],
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
                                           Deployment   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM]}],
      "Template Administrator" => [false, {Template     => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Template Creator"       => [false, {Template     => [VIEW,USE,    CRE]}],
      "Administrator"          => [false, {Provider     => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           HardwareProfile => [      MOD,CRE,VPRM,GPRM],
                                           Realm        => [     USE,MOD,CRE,VPRM,GPRM],
                                           User         => [VIEW,    MOD,CRE],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Deployment   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Template     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           BasePermissionObject => [ MOD,    VPRM,GPRM]}]}}
Role.transaction do
  roles.each do |role_scope, scoped_hash|
    scoped_hash.each do |role_name, role_def|
      role = Role.find_or_initialize_by_name(role_name)
      role.update_attributes({:name => role_name, :scope => role_scope.name,
                               :assign_to_owner => role_def[0]})
      role.save!
      role_def[1].each do |priv_type, priv_actions|
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

default_quota = Quota.create

default_pool = Pool.find_by_name("default_pool")
default_role = Role.find_by_name("Pool User")
default_template_role = Role.find_by_name("Template Creator")

settings = {"allow_self_service_logins" => "true",
  "self_service_default_quota" => default_quota,
  "self_service_default_pool" => default_pool,
  "self_service_default_role" => default_role,
  "self_service_default_template_obj" => BasePermissionObject.general_permission_scope,
  "self_service_default_template_role" => default_template_role,
  # perm list in the format:
  #   "[resource1_key, resource1_role], [resource2_key, resource2_role], ..."
  "self_service_perms_list" => "[self_service_default_pool,self_service_default_role], [self_service_default_template_obj,self_service_default_template_role]"}
settings.each_pair do |key, value|
  MetadataObject.set(key, value)
end

# Provider types actually supported
if ProviderType.all.empty?
  ProviderType.create!(:name => "Mock", :build_supported => true, :codename =>"mock")
  ProviderType.create!(:name => "Amazon EC2", :build_supported => true, :codename =>"ec2", :ssh_user => "ec2-user", :home_dir => "/home/ec2-user")
  ProviderType.create!(:name => "GoGrid", :codename =>"gogrid")
  ProviderType.create!(:name => "Rackspace", :codename =>"rackspace")
  ProviderType.create!(:name => "RHEV-M", :codename =>"rhevm")
  ProviderType.create!(:name => "OpenNebula", :codename =>"opennebula")
end

# fill table CredentialDefinitions by default values
if CredentialDefinition.all.empty?
  ProviderType.all.each do |provider_type|
    unless provider_type.codename == 'ec2'
      CredentialDefinition.create!(:name => 'username', :label => 'API Key', :input_type => 'text', :provider_type_id => provider_type.id)
      CredentialDefinition.create!(:name => 'password', :label => 'Secret', :input_type => 'password', :provider_type_id => provider_type.id)
    end
  end

  #for ec2 provider type
  ec2 = ProviderType.find_by_codename 'ec2'
  CredentialDefinition.create!(:name => 'username', :label => 'Username', :input_type => 'text', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'password', :label => 'Password', :input_type => 'password', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'account_id', :label => 'AWS Account ID', :input_type => 'text', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509private', :label => 'EC2 x509 private key', :input_type => 'file', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509public', :label => 'EC2 x509 public key', :input_type => 'file', :provider_type_id => ec2.id)
end
