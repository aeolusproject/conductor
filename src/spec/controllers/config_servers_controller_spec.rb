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

describe ConfigServersController do
  fixtures :all

  before(:each) do
    @tuser = FactoryGirl.create :tuser
  end

  context "editing config servers" do
    before(:each) do
      @config_server = Factory :mock_config_server
      @provider_account = @config_server.provider_account
      @admin_permission = Permission.create :role => Role.find(:first, :conditions => ['name = ?', 'base.provider.admin']),
                                            :permission_object => @provider_account.provider,
                                            :entity => FactoryGirl.create(:provider_admin_user).entity
      @admin = @admin_permission.user
    end

    it "should provide UI to edit an existing Config Server" do
      mock_warden(@admin)
      get :edit, :id => @config_server.id
      response.should be_success
      response.should render_template("edit")
    end

    it "should allow users with account modify permissions to update a Config Server" do
      mock_warden(@admin)
      post :update, :id => @config_server.id, :config_server => {:endpoint => "https://localhost", :key => "key", :secret => "secret"}
      response.should be_success
    end
  end

  context "creating config servers" do
    before(:each) do
      @provider_account = Factory :mock_provider_account
      @admin_permission = Permission.create :role => Role.find(:first, :conditions => ['name = ?', 'base.provider.admin']),
                                            :permission_object => @provider_account.provider,
                                            :entity => FactoryGirl.create(:provider_admin_user).entity
      @admin = @admin_permission.user
    end

    it "should provide UI to create a new Config Server" do
      mock_warden(@admin)
      get :new, :provider_account_id => @provider_account.id
      response.should be_success
      response.should render_template("new")
    end

    it "should allow users with account modify permissions to create a Config Server" do
      mock_warden(@admin)
      config_server = Factory :mock_config_server
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpiont => "https://localhost",
          :key => "key",
          :secret => "secret"
        }
      response.should redirect_to(provider_provider_account_path(@provider_account.provider, @provider_account))
      request.flash[:error].should be_nil
    end

    it "should fail creating a config server when the username or password is invalid" do
      mock_warden(@admin)
      config_server = Factory :invalid_credentials_config_server, :endpoint => "https://localhost", :key => "invalid", :secret => "invalid"
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpoint => "https://localhost",
          :key => "invalid",
          :secret => "invalid"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The Config Server information is invalid."
    end

    it "should fail creating a config server when the endpoint is invalid" do
      mock_warden(@admin)
      config_server = Factory :invalid_endpoint_config_server
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpoint => "invalid",
          :key => "key",
          :secret => "secret"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The Config Server information is invalid."
    end

    it "should require that endpoint is provided" do
      mock_warden(@admin)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpoint => "",
          :key => "key",
          :secret => "secret"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The Config Server information is invalid."
    end

    it "should require that key is provided" do
      mock_warden(@admin)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpoint => "https://localhost",
          :key => "",
          :secret => "secret"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The Config Server information is invalid."
    end

    it "should require that secret is provided" do
      mock_warden(@admin)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :endpoint => "https://localhost",
          :key => "key",
          :secret => ""
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The Config Server information is invalid."
    end
  end
end
