require 'spec_helper'

describe UsersController do
  fixtures :all
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

  describe "#create" do
    before(:each) do

    end

    context "user enters valid input" do
      it "should create user" do
        lambda {
          post :create, :user => { :login => "tuser2", :email => "tuser2@example.com",
                                   :password => "testpass",
                                   :password_confirmation => "testpass" }
        }.should change{ User.count }
        p = PortalPool.find_by_name("tuser2")
        p.should_not be_nil
        assigns[:user].login.should == p.owner.login
        p.name.should == "tuser2"
        p.permissions.size.should == 1
        p.permissions.any? {
          |perm| perm.role.name.eql?('Self-service Pool User')
        }.should be_true
        response.should redirect_to(account_path)
      end

      it "fails to create pool" do
        lambda {
          post :create, :user => {}
        }.should_not change{ User.count }
        p = PortalPool.find_by_name("tuser2")
        p.should be_nil
        returned_user = assigns[:user]
        returned_user.errors.empty?.should be_false
        returned_user.should have(2).errors_on(:login)
        returned_user.should have(2).errors_on(:email)
        returned_user.should have(1).error_on(:password)
        returned_user.should have(1).error_on(:password_confirmation)
        #assigns[:user].errors.find_all {|attr,msg|
        #  ["login", "email", "password",  "password_confirmation"].
        #  include?(attr).should be_true
        #}
        response.should  render_template('new')
      end
    end
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
