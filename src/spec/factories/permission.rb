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
    role { |r| Role.first(:conditions => ['name = ?', 'Administrator']) || FactoryGirl.create(:role, :name => 'Administrator') }
    permission_object { |r| BasePermissionObject.general_permission_scope }
    user { |r| r.association(:admin_user) }
  end

  factory :provider_admin_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'Provider Administrator']) || FactoryGirl.create(:role, :name => 'Provider Administrator') }
    permission_object { |r| r.association(:mock_provider) }
    user { |r| r.association(:provider_admin_user) }
  end

  factory :pool_creator_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'Pool Creator']) || FactoryGirl.create(:role, :name => 'Pool Creator') }
    permission_object { |r| BasePermissionObject.general_permission_scope }
    user { |r| r.association(:pool_creator_user) }
  end

  factory :pool_user_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'Pool User']) || FactoryGirl.create(:role, :name => 'Pool User') }
    permission_object { |r| r.association(:pool) }
    user { |r| r.association(:pool_user) }
  end

  factory :pool_user2_permission, :parent => :permission do
    role { |r| Role.first(:conditions => ['name = ?', 'Pool User']) || FactoryGirl.create(:role, :name => 'Pool User') }
    permission_object { |r| r.association(:pool) }
    user { |r| r.association(:pool_user2) }
  end

end
