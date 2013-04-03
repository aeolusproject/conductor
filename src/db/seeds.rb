#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Default Pool Family
PoolFamily.create!(:name => "default", :description => "default pool family", :quota => Quota.create)
# Default Pool
Pool.create!(:name => "Default", :quota => Quota.create, :pool_family => PoolFamily.find_by_name('default'), :enabled => true)

# Default Catalog
Catalog.create!(:name => "Default", :pool => Pool.find_by_name("Default"))

# Create default roles
VIEW = "view"
USE  = "use"
MOD  = "modify"
CRE  = "create"
VPRM = "view_perms"
GPRM = "set_perms"

# gettext strings for translation
# FIXME: this is a bit of a hack in that string literals must be passed into
#        the N_() call for the gettext parser to generate app.pot entries.
#        We should eventually come up with a way for the gettext parser
#        to pull these directly from the names column in the roles db table.
N_("Role|Global Administrator")
N_("Role|Global Deployable Administrator")
N_("Role|Global HWP Administrator")
N_("Role|Global HWP User")
N_("Role|Global Image Administrator")
N_("Role|Global Pool Administrator")
N_("Role|Global Pool User")
N_("Role|Global Provider Administrator")
N_("Role|Global Provider User")
N_("Role|Global Realm Administrator")

N_("Role|Catalog Administrator")
N_("Role|Catalog User")
N_("Role|Deployable Owner")
N_("Role|Deployable User")
N_("Role|Deployment Owner")
N_("Role|Deployment User")
N_("Role|Instance Owner")
N_("Role|Instance User")
N_("Role|Pool Administrator")
N_("Role|Pool Deployable Admin")
N_("Role|Pool User")
N_("Role|Environment Administrator")
N_("Role|Environment Image Administrator")
N_("Role|Environment User")
N_("Role|Provider Administrator")
N_("Role|Provider User")
N_("Role|Provider Account Owner")
N_("Role|Provider Account User")
N_("Role|Provider Type Owner")
N_("Role|Image Owner")
N_("Role|Image User")
N_("Role|Template Owner")
N_("Role|Template User")

roles =
  {Instance =>
     {"Role|Instance User"          => [false, {Instance        => [VIEW,USE]}],
      "Role|Instance Owner"         => [true,  {Instance        => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Deployment =>
     {"Role|Deployment User"        => [false, {Deployment      => [VIEW,USE],
                                                Instance        => [VIEW]}],
      "Role|Deployment Owner"       => [true,  {Deployment      => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD]}]},
    Tim::BaseImage =>
     {"Role|Image User"             => [false, {Tim::BaseImage  => [VIEW,USE]}],
      "Role|Image Owner"            => [true,  {Tim::BaseImage  => [VIEW,USE,MOD,    VPRM,GPRM]}]},
    Tim::Template =>
     {"Role|Template User"          => [false, {Tim::Template   => [VIEW,USE]}],
      "Role|Template Owner"         => [true,  {Tim::Template   => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   PoolFamily =>
     {"Role|Environment User"       => [false, {PoolFamily      => [VIEW]}],
      "Role|Environment Image Administrator"=>[false,{PoolFamily=> [VIEW,USE],
                                                Pool            => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::BaseImage  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::Template   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}],
      "Role|Environment Administrator"=> [true, {PoolFamily     => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Pool            => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::BaseImage  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::Template   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}]},
   Pool =>
     {"Role|Pool User"              => [false, {Pool            => [VIEW],
                                                Instance        => [             CRE],
                                                Deployment      => [             CRE],
                                                Catalog         => [VIEW, USE],
                                                Deployable      => [VIEW,USE],
                                                Quota           => [VIEW]}],
      "Role|Pool Deployable Admin"  => [false, {Pool            => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}],
      "Role|Pool Administrator"     => [true,  {Pool            => [VIEW,    MOD,    VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE],
                                                Deployment      => [VIEW,USE,MOD,CRE],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}]},
   ProviderType =>
     {"Role|Provider Type Owner"   => [true,  {ProviderType    => [MOD]}]},
   Provider =>
     {"Role|Provider Administrator" => [true,  {Provider        => [VIEW,USE,MOD,    VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Role|Provider User"          => [false,  {Provider        => [VIEW,USE],
                                                ProviderAccount => [             CRE]}]},
   ProviderAccount =>
     {"Role|Provider Account User"  => [false, {ProviderAccount => [VIEW,USE]}],
      "Role|Provider Account Owner" => [true,  {ProviderAccount => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Catalog =>
     {"Role|Catalog User"           => [false, {Catalog         => [VIEW, USE],
                                                Deployable      => [VIEW,USE]}],
      "Role|Catalog Administrator"  => [true,  {Catalog         => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}]},
   Deployable =>
     {"Role|Deployable User"        => [false, {Deployable      => [VIEW,USE]}],
      "Role|Deployable Owner"       => [true,  {Deployable      => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Alberich::BasePermissionObject =>
     {"Role|Global Provider User"   => [false, {Provider        => [VIEW,USE]}],
      "Role|Global Provider Administrator"=> [false, {Provider  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Role|Global HWP Administrator" => [false,{HardwareProfile=> [VIEW,    MOD,CRE,VPRM,GPRM]}],
      "Role|Global Realm Administrator"=> [false, {FrontendRealm=> [     USE,MOD,CRE,VPRM,GPRM]}],
      "Role|Global Pool Administrator" => [false, {Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::BaseImage  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::Template   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW,    MOD],
                                                PoolFamily      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Role|Global Deployable Administrator" => [false, {PoolFamily => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "Role|Global HWP User"        => [false, {HardwareProfile => [VIEW,USE]}],
      "Role|Global Pool User"       => [false, {PoolFamily      => [VIEW],
                                                Pool            => [VIEW],
                                                Instance        => [             CRE],
                                                Deployment      => [             CRE],
                                                Deployable      => [VIEW,USE],
                                                Catalog         => [VIEW,USE],
                                                Quota           => [VIEW]}],
      "Role|Global Image Administrator" => [false, {PoolFamily  => [VIEW, USE],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::BaseImage  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::Template   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE]}],
      "Role|Global Administrator"   => [false, {ProviderType    => [MOD],
                                                Provider        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                HardwareProfile => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                FrontendRealm   => [     USE,MOD,CRE,VPRM,GPRM],
                                                User            => [VIEW,    MOD,CRE],
                                                Pool            => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW,    MOD],
                                                PoolFamily      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::BaseImage  => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Tim::Template   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Alberich::BasePermissionObject    => [ MOD,    VPRM,GPRM]}]}}
Alberich::Role.transaction do
  roles.each do |role_scope, scoped_hash|
    scoped_hash.each do |role_name, role_def|
      role = Alberich::Role.find_or_initialize_by_name(role_name)
      role.update_attributes({:name => role_name, :scope => role_scope.name,
                               :assign_to_owner => role_def[0]})
      role.save!
      role_def[1].each do |priv_type, priv_actions|
        priv_actions.each do |action|
          Alberich::Privilege.create!(:role => role, :target_type => priv_type.name,
                            :action => action)
        end
      end
    end
  end
end

# Set meta objects
default_pool_family = PoolFamily.find_by_name('default')
default_pool_family_role = Alberich::Role.find_by_name('Role|Environment User')
MetadataObject.set("default_pool_family", default_pool_family)

default_quota = Quota.create

default_pool = Pool.find_by_name("Default")
default_role = Alberich::Role.find_by_name("Role|Pool User")
default_hwp_global_user_role = Alberich::Role.find_by_name("Role|Global HWP User")

settings = {"allow_self_service_logins" => "true",
  "self_service_default_quota" => default_quota,
  "self_service_default_pool" => default_pool,
  "self_service_default_role" => default_role,
  "self_service_default_pool_family" => default_pool_family,
  "self_service_default_pool_family_role" => default_pool_family_role,
  "self_service_default_hwp_global_user_obj" => Alberich::BasePermissionObject.general_permission_scope,
  "self_service_default_hwp_global_user_role" => default_hwp_global_user_role,
  # perm list in the format:
  #   "[resource1_key, resource1_role], [resource2_key, resource2_role], ..."
  "self_service_perms_list" => "[self_service_default_pool,self_service_default_role], [self_service_default_pool_family,self_service_default_pool_family_role],[self_service_default_hwp_global_user_obj,self_service_default_hwp_global_user_role] "}
settings.each_pair do |key, value|
  MetadataObject.set(key, value)
end

# Provider types actually supported
if ProviderType.all.empty?
  ProviderType.create!(:name => "Mock", :deltacloud_driver =>"mock")
  ProviderType.create!(:name => "Amazon EC2", :deltacloud_driver =>"ec2", :ssh_user => "root", :home_dir => "/root")
  ProviderType.create!(:name => "RHEV-M", :deltacloud_driver =>"rhevm")
  ProviderType.create!(:name => "VMware vSphere", :deltacloud_driver =>"vsphere")
  ProviderType.create!(:name => "Rackspace", :deltacloud_driver => "rackspace")
  ProviderType.create!(:name => "OpenStack", :deltacloud_driver => "openstack")
end

# fill table CredentialDefinitions by default values
if CredentialDefinition.all.empty?
  ProviderType.all.each do |provider_type|
    unless provider_type.deltacloud_driver == 'ec2'
      CredentialDefinition.create!(:name => 'username', :label => 'username', :input_type => 'string', :provider_type_id => provider_type.id)
      CredentialDefinition.create!(:name => 'password', :label => 'password', :input_type => 'password', :provider_type_id => provider_type.id)
    end
  end

  #for ec2 provider type
  ec2 = ProviderType.find_by_deltacloud_driver 'ec2'
  CredentialDefinition.create!(:name => 'username', :label => 'access_key', :input_type => 'string', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'password', :label => 'secret_access_key', :input_type => 'password', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'account_id', :label => 'account_number', :input_type => 'string', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509private', :label => 'key', :input_type => 'file', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509public', :label => 'certificate', :input_type => 'file', :provider_type_id => ec2.id)

  # For OpenStack provider type:
  if openstack = ProviderType.find_by_deltacloud_driver('openstack')
    CredentialDefinition.create!(:name => 'glance_url', :label => 'glance_url', :input_type => 'string', :provider_type_id => openstack.id)
  end
end
