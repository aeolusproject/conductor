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

describe PermissionsController do

  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  it "should redirect to the appropriate path for the PermissionObject" do
    mock_warden(@admin)

    @catalog = FactoryGirl.create(:catalog)
    @deployable = FactoryGirl.create(:deployable, :catalogs => [@catalog])

    @old_role = FactoryGirl.create(:role)
    @new_role = FactoryGirl.create(:role)
    @permission = FactoryGirl.create(:permission, :entity => @admin.entity, :role => @old_role, :permission_object => @deployable)

    post :multi_update, :permission_object_id => @deployable.id, :permission_object_type => @deployable.class.to_s,
        :permission_role_selected => ["#{@permission.id},#{@new_role.id}"], :polymorphic_path_extras => { 'catalog_id' => @catalog.id}

    response.should redirect_to catalog_deployable_path(@catalog, @deployable, :return_from_permission_change => true)
  end

  it "should work for global role grants" do
    mock_warden(@admin)
    get :index
    response.should be_success
  end


end
