#
#   Copyright 2012 Red Hat, Inc.
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

describe Tim::TemplatesController do

  fixtures :all

  before(:each) do
    @template = FactoryGirl.create(:template)
    @template2 = FactoryGirl.build(:template_i386)
  end

  context "unauthorised user" do
    before(:each) do
      @user_permission = FactoryGirl.create :pool_user_permission
      @user = @user_permission.user
      mock_warden(@user)
    end

    it "should see empty list of templates" do
      get :index
      response.should be_success
      assigns[:templates].size.should == 0
    end

    it "should not be able to create new template" do
      post :create, :template => {:xml => @template2.xml}
      response.status.should == 403
    end

    it "should not be able to update existing template" do
      put :update, :id => @template.id, :template => {:xml => @template2.xml}
      response.status.should == 403
    end

    it "should not be able to delete existing template" do
      delete :destroy, :id => @template.id
      response.status.should == 403
    end

  end

  # currently we test only permissions, so model actions are stubbed
  context "pool family admin" do
    before(:each) do
      @admin_permission = FactoryGirl.create :admin_permission
      @admin = @admin_permission.user
      mock_warden(@admin)
    end

    it "should see permissioned list of templates" do
      get :index
      response.should be_success
      assigns[:templates].size.should == 1
    end

    it "should be able to create new template" do
      Tim::Template.any_instance.stub(:save).and_return(true)
      post :create, :template => {:xml => @template2.xml}
      response.status.should == 302
    end

    it "should be able to update existing template" do
      Tim::Template.any_instance.stub(:update_attributes).and_return(true)
      put :update, :id => @template.id, :template => {:xml => @template2.xml}
      response.status.should == 302
    end

    it "should be able to delete existing template" do
      Tim::Template.any_instance.stub(:destroy).and_return(true)
      delete :destroy, :id => @template.id
      response.status.should == 302
    end
  end
end
