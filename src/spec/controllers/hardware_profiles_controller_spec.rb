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

describe HardwareProfilesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  describe "Authorization" do

    context "Admin" do
      it "should provide ui to view all hardware profiles" do
        mock_warden(@admin)
        @request.accept = "text/html"
        get :index
        response.should be_success
        assigns[:hardware_profiles].size.should == HardwareProfile.count
        response.should render_template("index")
      end

      it "should be able to create hardware profiles" do
        mock_warden(@admin)
        lambda do
          post :create, :commit => 'Save', :hardware_profile => {
            :name => 'test',
            :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
            :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
            :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
            :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
          }
        end.should change(HardwareProfile, :count).by(1)
        HardwareProfile.find_by_name('test').should_not be_nil
        response.should redirect_to(hardware_profiles_path)
      end

      it "should be able to edit hardware profiles" do
        hardware_profile = Factory.create :hardware_profile
        mock_warden(@admin)
        put :update, :id => hardware_profile.id, :hardware_profile => {
          :name => 'updated hwp',
          :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
          :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
          :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
          :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
        }
        HardwareProfile.find_by_name('updated hwp').should_not be_nil
        response.should redirect_to(hardware_profiles_path)
      end

      it "should be able to delete hardware profiles" do
        hardware_profile = Factory.create :hardware_profile
        mock_warden(@admin)

        HardwareProfile.exists?(hardware_profile.id).should be_true
        delete :destroy, :id => hardware_profile.id
        HardwareProfile.exists?(hardware_profile.id).should be_false
        response.should redirect_to(hardware_profiles_path)
      end

    end


    context "Unauthorized user" do
      before(:each) do
        @user_permission = FactoryGirl.create :pool_user_permission
        @user = @user_permission.user
      end

      it "should not list hw profiles which I'm not allowed to see" do
        hardware_profile = Factory.create :hardware_profile
        mock_warden(@user)
        @request.accept = "text/html"
        get :index
        response.should be_success
        assigns[:hardware_profiles].find {|p| p.name == hardware_profile.name}.should be_nil
        response.should render_template("index")
      end

      it "should not be able to create hardware profiles" do
        mock_warden(@user)
        lambda do
          post :create, :commit => 'Save', :hardware_profile => {
            :name => 'test',
            :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
            :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
            :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
            :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
          }
        end.should_not change(HardwareProfile, :count)
        HardwareProfile.find_by_name('test').should be_nil
        response.should render_template('layouts/error')
      end

      it "should not be able to edit hardware profiles" do
        hardware_profile = Factory.create :hardware_profile
        mock_warden(@user)
        put :update, :id => hardware_profile.id, :hardware_profile => {
          :name => 'updated hwp',
          :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
          :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
          :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
          :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
        }
        HardwareProfile.find_by_name('updated hwp').should be_nil
        response.should render_template('layouts/error')
      end


      it "should not be able to delete hardware profiles" do
        hardware_profile = Factory.create :hardware_profile
        mock_warden(@user)

        HardwareProfile.exists?(hardware_profile.id).should be_true
        delete :destroy, :id => hardware_profile.id
        HardwareProfile.exists?(hardware_profile.id).should be_true
        response.should render_template('layouts/error')
      end
    end

  end
end
