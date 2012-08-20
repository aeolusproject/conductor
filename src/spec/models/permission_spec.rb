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
    @session = FactoryGirl.create :session
    @session_id = @session.session_id
    @permission_session = PermissionSession.create!(:user => @admin,
                                                    :session_id => @session_id)
    @permission_session.update_session_entities(@admin)
    @permission_session.add_to_session(@provider_admin)
    @permission_session.add_to_session(@pool_user)
  end

  it "Admin should be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@permission_session,
                                                                @admin,
                                                                Privilege::CREATE,
                                                                User).should be_true
  end

  it "Provider Admin should NOT be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@permission_session,
                                                                @provider_admin,
                                                                Privilege::CREATE,
                                                                User).should be_false
  end

  it "Pool User should NOT be able to create users" do
    BasePermissionObject.general_permission_scope.has_privilege(@permission_session,
                                                                @pool_user,
                                                                Privilege::CREATE,
                                                                User).should be_false
  end

  it "Provider Admin should be able to edit provider" do
    @provider.has_privilege(@permission_session, @provider_admin,
                            Privilege::MODIFY).should be_true
  end

  it "Admin should be able to edit provider" do
    @provider.has_privilege(@permission_session, @admin, Privilege::MODIFY).should be_true
  end

  it "Pool User should NOT be able to edit provider" do
    @provider.has_privilege(@permission_session, @pool_user,
                            Privilege::MODIFY).should be_false
  end

  it "Pool User should be able to create instances in @pool" do
    @pool.has_privilege(@permission_session, @pool_user,
                        Privilege::CREATE, Instance).should be_true
  end

  it "Pool User should NOT be able to create instances in another pool" do
    FactoryGirl.create(:tpool).has_privilege(@permission_session, @pool_user,
                                             Privilege::CREATE, Instance).
      should be_false
  end

  it "User added to Admin group should be able to create users" do
    newuser = FactoryGirl.create(:user)
    group_admin_permission = FactoryGirl.create(:group_admin_permission)
    user_group = group_admin_permission.user_group
    @permission_session.update_session_entities(newuser)
    BasePermissionObject.general_permission_scope.has_privilege(@permission_session,
                                                                newuser,
                                                                Privilege::CREATE,
                                                                User).should be_false
    user_group.members << newuser
    newuser.reload
    @permission_session.update_session_entities(newuser)
    BasePermissionObject.general_permission_scope.has_privilege(@permission_session,
                                                                newuser,
                                                                Privilege::CREATE,
                                                                User).should be_true

  end

end
