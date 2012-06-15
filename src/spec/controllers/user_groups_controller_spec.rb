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

describe UserGroupsController do

  fixtures :all
  before(:each) do
    @user_group = Factory.create(:user_group)
    @tuser = FactoryGirl.create :tuser
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  describe "#create" do
    context "user enters valid input" do
      it "creates user group" do
        mock_warden(@admin)
        lambda do
          post :create, :user_group => {
            :name => "user_group2", :membership_source => "local" }
        end.should change(UserGroup, :count).by(1)

        response.should redirect_to(user_groups_path)
      end

      it "fails to create user" do
        mock_warden(@admin)
        lambda do
          post :create, :user_group => {}
        end.should_not change(UserGroup, :count)

        returned_user_group = assigns[:user_group]
        returned_user_group.errors.empty?.should be_false
        returned_user_group.should have(1).errors_on(:name)
        returned_user_group.should have(2).errors_on(:membership_source)

        response.should render_template('new')
      end
    end
  end

  it "allows an admin to create user group" do
    mock_warden(@admin)
    lambda do
      post :create, :user_group => {
           :name => "user_group3", :membership_source => "local" }
    end.should change(UserGroup, :count)

    response.should redirect_to(user_groups_url)
  end

  it "should not allow a regular user to create user group" do
    mock_warden(@tuser)
    lambda do
      post :create, :user_group => {
           :name => "user_group4", :membership_source => "local" }
    end.should_not change(UserGroup, :count)
  end

end
