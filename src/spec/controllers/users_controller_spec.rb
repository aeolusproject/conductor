require 'spec_helper'

describe UsersController do

  before(:each) do
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "should call new method" do
    route_for(:controller => 'user_sessions', :action => 'new').should == 'login'
    get :new
    @current_user.should == nil
    UserSession.find.should == nil
    response.should be_success
  end

  it "should create user" do
    lambda {
      post :create, :user => { :login => "tuser2", :email => "tuser2@example.com",
                               :password => "testpass",
                               :password_confirmation => "testpass" }
    }.should change{ User.count }
    response.should redirect_to(account_path)
  end

  it "should show user" do
    UserSession.create(@tuser)
    get :show
    response.should be_success
  end

  it "should get edit" do
    UserSession.create(@tuser)
    get :edit, :id => @tuser.id
    response.should be_success
  end

  test "should update user" do
    UserSession.create(@tuser)
    put :update, :id => @tuser.id, :user => { }
    response.should redirect_to(account_path)
  end
end
