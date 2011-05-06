require 'spec_helper'

describe ProvidersController do

  fixtures :all
  before(:each) do
    @admin_permission = Factory :provider_admin_permission
    @provider = @admin_permission.permission_object
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should provide ui to view hardware profiles" do
     UserSession.create(@admin)
     provider = @admin_permission.permission_object

     get :show, :id => provider.id, :details_tab => 'hw_profiles'
     response.should be_success
     assigns[:hardware_profiles].size.should == provider.hardware_profiles.size
     response.should render_template("providers/_hw_profiles")
  end

  it "should provide ui to view realms" do
     UserSession.create(@admin)
     provider = @admin_permission.permission_object

     get :show, :id => provider.id, :details_tab => 'realms'
     response.should be_success
     assigns[:realm_names].size.should == provider.realms.size
     response.should render_template("providers/_realms")
  end


end
