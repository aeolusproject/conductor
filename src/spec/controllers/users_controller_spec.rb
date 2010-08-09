require 'spec_helper'

describe UsersController do
  fixtures :all
  before(:each) do
    @tuser = Factory :tuser
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
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
        p = Pool.find_by_name("tuser2")
        p.should_not be_nil
        assigns[:user].login.should == p.owner.login
        p.name.should == "tuser2"
        p.permissions.size.should == 1
        p.permissions.any? {
          |perm| perm.role.name.eql?('Instance Creator and User')
        }.should be_true
        user = User.find(:first, :conditions => ['login = ?', "tuser2"])
        response.should redirect_to(user_url(user))
      end

      it "fails to create pool" do
        lambda {
          post :create, :user => {}
        }.should_not change{ User.count }
        p = Pool.find_by_name("tuser2")
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

  it "should allow an admin to create user" do
    UserSession.create(@admin)
    lambda {
      post :create, :user => { :login => "tuser3", :email => "tuser3@example.com",
                               :password => "testpass",
                               :password_confirmation => "testpass" }
    }.should change{ User.count }
    user = User.find(:first, :conditions => ['login = ?', "tuser3"])
    response.should redirect_to(user_url(user))
  end

  it "should not allow a regular user to create user" do
    UserSession.create(@tuser)
    lambda {
      post :create, :user => { :login => "tuser4", :email => "tuser4@example.com",
                               :password => "testpass",
                               :password_confirmation => "testpass" }
    }.should_not change{ User.count }
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

  # checks whether proper error template is rendered when an exception raises
  # "layouts/error" template should be displayed for all non-ajax error
  # responses, "layouts/popup-error" should be displayed for ajax
  # (see "Fixed error handling" patch for details)
  it "should render error template when getting nonexisting user" do
    UserSession.create(@tuser)
    get :show, :id => "unknown_id"
    response.should render_template("layouts/error")
  end
end
