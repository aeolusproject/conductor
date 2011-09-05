require 'spec_helper'

describe UsersController do

  fixtures :all
  before(:each) do
    @tuser = FactoryGirl.create :tuser
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  it "allows user to get to registration form for new user" do
    get :new
    response.should be_success
  end

  describe "#create" do
    context "user enters valid input" do
      it "creates user" do
        mock_warden(@admin)
        lambda do
          post :create, :user => {
            :login => "tuser2", :email => "tuser2@example.com",
            :password => "testpass",
            :password_confirmation => "testpass" }
        end.should change(User, :count).by(1)

        response.should redirect_to(users_path)
      end

      it "fails to create pool" do
        mock_warden(@admin)
        lambda do
          post :create, :user => {}
        end.should_not change(User, :count)

        returned_user = assigns[:user]
        returned_user.errors.empty?.should be_false
        returned_user.should have(1).errors_on(:login)
        #returned_user.should have(1).errors_on(:email)
        returned_user.should have(1).error_on(:password)

        response.should render_template('new')
      end
    end
  end

  it "allows an admin to create user" do
    mock_warden(@admin)
    lambda do
      post :create, :user => {
        :login => "tuser3", :email => "tuser3@example.com",
        :password => "testpass",
        :password_confirmation => "testpass" }
    end.should change(User, :count)

    response.should redirect_to(users_url)
  end

  it "should not allow a regular user to create user" do
    mock_warden(@tuser)
    lambda do
      post :create, :user => {
        :login => "tuser4", :email => "tuser4@example.com",
        :password => "testpass",
        :password_confirmation => "testpass" }
    end.should_not change(User, :count)
  end

  it "provides show view for user" do
    mock_warden(@tuser)
    get :show

    response.should be_success
  end

  it "provides edit view for user" do
    mock_warden(@tuser)
    get :edit, :id => @tuser.id

    response.should be_success
  end

  it "updates user with new data" do
    mock_warden(@tuser)
    put :update, :id => @tuser.id, :user => {}, :commit => 'Save'

    response.should redirect_to(user_path(@tuser))
  end

end
