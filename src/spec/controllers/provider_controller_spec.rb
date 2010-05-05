require 'spec_helper'

describe ProviderController do

  fixtures :all
  before(:each) do
    @admin_permission = Factory :provider_admin_permission
    @provider = @admin_permission.permission_object
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should provide ui to view accounts" do
     UserSession.create(@admin)
     get :accounts, :id => @provider.id
     response.should be_success
     response.should render_template("accounts")
  end

  it "should fail to grant access to account UIs for unauthenticated user" do
     get :accounts
     response.should_not be_success
  end

  it "should provide ui to view hardware profiles" do
     UserSession.create(@admin)
     provider = @admin_permission.permission_object

     get :hardware_profiles, :id => provider.id
     response.should be_success
     assigns[:hardware_profiles].size.should == provider.hardware_profiles.size
     response.should render_template("hardware_profiles")
  end

  it "should provide ui to view realms" do
     UserSession.create(@admin)
     provider = @admin_permission.permission_object

     get :realms, :id => provider.id
     response.should be_success
     assigns[:realm_names].size.should == provider.realms.size
     response.should render_template("realms")
  end


end
