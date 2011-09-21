#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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
