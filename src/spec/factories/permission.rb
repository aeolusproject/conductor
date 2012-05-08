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

FactoryGirl.define do

  factory :permission do
    after_build { |p| p.user.permissions << p }
  end

  factory :admin_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'base.admin']) || FactoryGirl.create(:role, :name => 'base.admin') }
    permission_object { |r| BasePermissionObject.general_permission_scope }
    user { |r| r.association(:admin_user) }
  end

  factory :provider_admin_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'base.provider.admin']) || FactoryGirl.create(:role, :name => 'base.provider.admin') }
    permission_object { |r| r.association(:mock_provider) }
    user { |r| r.association(:provider_admin_user) }
  end

  factory :pool_creator_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'base.pool.creator']) || FactoryGirl.create(:role, :name => 'base.pool.creator') }
    permission_object { |r| BasePermissionObject.general_permission_scope }
    user { |r| r.association(:pool_creator_user) }
  end

  factory :pool_user_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'pool.user']) || FactoryGirl.create(:role, :name => 'pool.user') }
    permission_object { |r| r.association(:pool) }
    user { |r| r.association(:pool_user) }
  end

  factory :pool_user2_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'pool.user']) || FactoryGirl.create(:role, :name => 'pool.user') }
    permission_object { |r| r.association(:pool) }
    user { |r| r.association(:pool_user2) }
  end

  factory :pool_family_user_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'pool_family.user']) || FactoryGirl.create(:role, :name => 'pool_family.user') }
    permission_object { |r| r.association(:pool_family) }
    user { |r| r.association(:pool_family_user) }
  end

  factory :pool_family_admin_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'pool_family.admin']) || FactoryGirl.create(:role, :name => 'pool_family.admin') }
    permission_object { |r| r.association(:pool_family) }
    user { |r| r.association(:pool_family_user) }
  end

end
