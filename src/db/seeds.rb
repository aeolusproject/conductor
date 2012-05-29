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

roles =
  {Instance =>
     {"instance.user"               => [false, {Instance        => [VIEW,USE]}],
      "instance.owner"              => [true,  {Instance        => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Deployment =>
     {"deployment.user"             => [false, {Deployment      => [VIEW,USE],
                                                Instance        => [VIEW]}],
      "deployment.owner"            => [true,  {Deployment      => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD]}]},
   PoolFamily =>
     {"pool_family.user"            => [false, {PoolFamily      => [VIEW]}],
      "pool_family.image.admin"     => [false, {PoolFamily      => [VIEW,USE],
                                                Pool            => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}],
      "pool_family.admin"           => [true,  {PoolFamily      => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Pool            => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}]},
   Pool =>
     {"pool.user"                   => [false, {Pool            => [VIEW],
                                                Instance        => [             CRE],
                                                Deployment      => [             CRE],
                                                Catalog         => [VIEW, USE],
                                                Deployable      => [VIEW,USE],
                                                Quota           => [VIEW]}],
      "pool.deployable.admin"       => [false, {Pool            => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}],
      "pool.admin"                  => [true,  {Pool            => [VIEW,    MOD,    VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE],
                                                Deployment      => [VIEW,USE,MOD,CRE],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW]}]},
   Provider =>
     {"provider.admin"              => [true,  {Provider        => [VIEW,USE,MOD,    VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "provider.user"               => [false,  {Provider        => [VIEW,USE],
                                                ProviderAccount => [             CRE]}]},
   ProviderAccount =>
     {"provider_account.user"       => [false, {ProviderAccount => [VIEW,USE]}],
      "provider_account.owner"      => [true,  {ProviderAccount => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   Catalog =>
     {"catalog.user"                => [false, {Catalog         => [VIEW, USE],
                                                Deployable      => [VIEW,USE]}],
      "catalog.admin"               => [true,  {Catalog         => [VIEW,USE,MOD,    VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}]},
   Deployable =>
     {"deployable.user"             => [false, {Deployable      => [VIEW,USE]}],
      "deployable.owner"            => [true,  {Deployable      => [VIEW,USE,MOD,    VPRM,GPRM]}]},
   BasePermissionObject =>
     {"base.provider.user"          => [false, {Provider        => [VIEW,USE]}],
      "base.provider.admin"         => [false, {Provider        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "base.hwp.admin"              => [false, {HardwareProfile => [VIEW,    MOD,CRE,VPRM,GPRM]}],
      "base.realm.admin"            => [false, {Realm           => [     USE,MOD,CRE,VPRM,GPRM]}],
      "base.pool.admin"             => [false, {Pool            => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW,    MOD],
                                                PoolFamily      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "base.deployable.admin"       => [false, {PoolFamily      => [VIEW],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM]}],
      "base.hwp.user"               => [false, {HardwareProfile => [VIEW,USE]}],
      "base.pool.user"              => [false, {PoolFamily      => [VIEW],
                                                Pool            => [VIEW],
                                                Instance        => [             CRE],
                                                Deployment      => [             CRE],
                                                Deployable      => [VIEW,USE],
                                                Catalog         => [VIEW,USE],
                                                Quota           => [VIEW]}],
      "base.image.admin"            => [false, {PoolFamily      => [VIEW, USE],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE]}],
      "base.admin"                  => [false, {Provider        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                HardwareProfile => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Realm           => [     USE,MOD,CRE,VPRM,GPRM],
                                                User            => [VIEW,    MOD,CRE],
                                                Pool            => [VIEW,    MOD,CRE,VPRM,GPRM],
                                                Instance        => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployment      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Quota           => [VIEW,    MOD],
                                                PoolFamily      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Catalog         => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                Deployable      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                                BasePermissionObject    => [ MOD,    VPRM,GPRM]}]}}
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

# Set meta objects
default_pool_family = PoolFamily.find_by_name('default')
default_pool_family_role = Role.find_by_name('pool_family.user')
MetadataObject.set("default_pool_family", default_pool_family)

default_quota = Quota.create

default_pool = Pool.find_by_name("Default")
default_role = Role.find_by_name("pool.user")
default_hwp_global_user_role = Role.find_by_name("base.hwp.user")

settings = {"allow_self_service_logins" => "true",
  "self_service_default_quota" => default_quota,
  "self_service_default_pool" => default_pool,
  "self_service_default_role" => default_role,
  "self_service_default_pool_family" => default_pool_family,
  "self_service_default_pool_family_role" => default_pool_family_role,
  "self_service_default_hwp_global_user_obj" => BasePermissionObject.general_permission_scope,
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
  ProviderType.create!(:name => "Openstack", :deltacloud_driver => "openstack")
end

# fill table CredentialDefinitions by default values
if CredentialDefinition.all.empty?
  ProviderType.all.each do |provider_type|
    unless provider_type.deltacloud_driver == 'ec2'
      CredentialDefinition.create!(:name => 'username', :label => 'username', :input_type => 'text', :provider_type_id => provider_type.id)
      CredentialDefinition.create!(:name => 'password', :label => 'password', :input_type => 'password', :provider_type_id => provider_type.id)
    end
  end

  #for ec2 provider type
  ec2 = ProviderType.find_by_deltacloud_driver 'ec2'
  CredentialDefinition.create!(:name => 'username', :label => 'access_key', :input_type => 'text', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'password', :label => 'secret_access_key', :input_type => 'password', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'account_id', :label => 'account_number', :input_type => 'text', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509private', :label => 'key', :input_type => 'file', :provider_type_id => ec2.id)
  CredentialDefinition.create!(:name => 'x509public', :label => 'certificate', :input_type => 'file', :provider_type_id => ec2.id)
end
