require 'spec_helper'

describe UserSessionsController do

  fixtures :all
  before(:each) do
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "should call new method" do
    {:get => 'login'}.should route_to(:controller => 'user_sessions', :action => 'new')
    get :new
    @current_user.should == nil
    UserSession.find.should == nil
    response.should be_success
  end

  it "should create user session" do
    post :create, :user_session => { :login => @tuser.login, :password => "secret" }
    UserSession.find.should_not == nil
    @tuser.should == UserSession.find.user
    response.should redirect_to(root_url)
  end

  it "should destroy user session" do
    post :create, :user_session => { :login => @tuser.login, :password => "secret" }
    delete :destroy
    UserSession.find.should == nil
    response.should redirect_to(login_path)
  end
end
