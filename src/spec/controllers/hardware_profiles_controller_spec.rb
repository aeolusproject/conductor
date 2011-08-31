require 'spec_helper'

describe HardwareProfilesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  it "should provide ui to view all hardware profiles" do
     mock_warden(@admin)
     @request.accept = "text/html"
     get :index
     response.should be_success
     assigns[:hardware_profiles].size.should == HardwareProfile.count
     response.should render_template("index")
  end

end
