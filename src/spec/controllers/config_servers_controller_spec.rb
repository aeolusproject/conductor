require 'spec_helper'

describe ConfigServersController do
  fixtures :all

  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    activate_authlogic
    @session = UserSession.create(@admin)
  end

  context "editing config servers" do
    before(:each) do
      @config_server = Factory :mock_config_server
      @provider_account = @config_server.provider_account
    end

    it "should provide UI to edit an existing Config Server" do
      get :edit, :id => @config_server.id
      response.should be_success
      response.should render_template("edit")
    end

    it "should allow users with account modify permissions to update a Config Server" do
      post :update, :id => @config_server.id, :config_server => {:host => "host", :port => "port"}
      response.should be_success
    end
  end

  context "creating config servers" do
    before(:each) do
      @provider_account = Factory :mock_provider_account
    end

    it "should provide UI to create a new Config Server" do
      get :new, :provider_account_id => @provider_account.id
      response.should be_success
      response.should render_template("new")
    end

    it "should allow users with account modify permissions to create a Config Server" do
      config_server = Factory :mock_config_server, :host => "host", :port => "port"
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :host => "host",
          :port => "port"
        }
      response.should redirect_to(provider_account_path(@provider_account.id))
      request.flash[:error].should be_nil
    end

    it "should fail creating a config server when the username or password is invalid" do
      config_server = Factory :invalid_credentials_config_server, :host => "host", :port => "port", :username => "invalid", :password => "invalid"
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :host => "host",
          :port => "port",
          :username => "invalid",
          :password => "invalid"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The config server information is invalid."
    end

    it "should fail creating a config server when the host and port are invalid" do
      config_server = Factory :invalid_host_or_port_config_server, :host => "invalid", :port => "invalid"
      ConfigServer.stub!(:new).and_return(config_server)
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :host => "invalid",
          :port => "invalid"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The config server information is invalid."
    end

    it "should require that port is provided" do
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :host => "host",
          :port => ""
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The config server information is invalid."
    end

    it "should require that host is provided" do
      post :create, :provider_account_id => @provider_account.id,
        :config_server => {
          :host => "",
          :port => "port"
        }
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "The config server information is invalid."
    end
  end
end
