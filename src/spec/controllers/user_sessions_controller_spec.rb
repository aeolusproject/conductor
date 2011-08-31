require 'spec_helper'
include Warden::Test::Helpers

describe UserSessionsController do

  fixtures :all
  before(:each) do
    @tuser = FactoryGirl.create :tuser
  end
  after(:each) do
    Warden.test_reset!
  end

  it "should call new method" do
    {:get => 'login'}.should route_to(:controller => 'user_sessions', :action => 'new')
    get :new
    response.should be_success
  end

  it "should create user session" do
    mock_warden(nil)
    post :create, :user_session => { :login => @tuser.login, :password => "secret" }
    response.should redirect_to(root_url)
  end

  it "should destroy user session" do
    mock_warden(@tuser)
    delete :destroy
    response.should redirect_to(login_path)
  end
end
