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

require 'spec_helper'

describe Permission do

  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @provider_admin_permission = FactoryGirl.create :provider_admin_permission
    @pool_creator_permission = FactoryGirl.create :pool_creator_permission
    @pool_user_permission = FactoryGirl.create :pool_user_permission

    @admin = @admin_permission.user
    @provider_admin = @provider_admin_permission.user
    @pool_creator = @pool_creator_permission.user
    @pool_user = @pool_user_permission.user

    @provider = @provider_admin_permission.provider
    @pool = @pool_user_permission.pool
  end

  it "Admin should be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@admin,
                                                                Privilege::CREATE,
                                                                User).should be_true
  end

  it "Provider Admin should NOT be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@provider_admin,
                                                                Privilege::CREATE,
                                                                User).should be_false
  end

  it "Pool User should NOT be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@pool_user,
                                                                Privilege::CREATE,
                                                                User).should be_false
  end

  it "Provider Admin should be able to edit provider" do
    @provider.has_privilege(@provider_admin, Privilege::MODIFY).should be_true
  end

  it "Admin should be able to edit provider" do
    @provider.has_privilege(@admin, Privilege::MODIFY).should be_true
  end

  it "Pool User should NOT be able to edit provider" do
    @provider.has_privilege(@pool_user, Privilege::MODIFY).should be_false
  end

  it "Pool User should be able to create instances in @pool" do
    @pool.has_privilege(@pool_user, Privilege::CREATE, Instance).should be_true
  end

  it "Pool User should NOT be able to create instances in another pool" do
    FactoryGirl.create(:tpool).has_privilege(@pool_user, Privilege::CREATE, Instance).should be_false
  end

end
