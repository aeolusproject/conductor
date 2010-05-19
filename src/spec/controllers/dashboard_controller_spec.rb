require 'spec_helper'

describe DashboardController do

  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should provide access to the dashboard" do
     UserSession.create(@admin)
     get :index
     response.should be_success
     response.should render_template("summary")
  end

end
