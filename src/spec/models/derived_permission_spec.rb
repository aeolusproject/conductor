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

describe DerivedPermission do

  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @provider_admin_permission = FactoryGirl.create :provider_admin_permission
    @pool_creator_permission = FactoryGirl.create :pool_creator_permission
    @pool_user_permission = FactoryGirl.create :pool_user_permission

    @admin = @admin_permission.user
    @provider_admin = @provider_admin_permission.user
    @pool_user = @pool_user_permission.user

    @provider = @provider_admin_permission.provider
    @pool = @pool_user_permission.pool
    @instance = Factory.create(:instance, :pool_id => @pool.id)
  end

  it "derived permissions created for instance" do
    derived_perms_count = @instance.derived_permissions.size
    @pool_perm = Permission.create(:entity => @admin.entity,
                                    :role => Role.first(:conditions =>
                                               ['name = ?', 'pool.admin']),
                                     :permission_object => @pool)
    @instance.reload
    inst_perm_sources = @instance.derived_permissions.collect {|p| p.permission}
    inst_perm_sources.size.should == (derived_perms_count + 1)
    inst_perm_sources.include?(@pool_user_permission).should be_true
    inst_perm_sources.include?(@pool_perm).should be_true
    instance2 = Factory.create(:instance, :pool_id => @pool.id)
    instance2.derived_permissions.collect {|p| p.permission}.include?(@pool_perm).should be_true
  end
end
