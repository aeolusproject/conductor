require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  fixtures :users

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => { :login => "tuser2", :email => "tuser2@example.com",
                               :password => "testpass",
                               :password_confirmation => "testpass" }
    end

    assert_redirected_to account_path
  end

  test "should show user" do
    UserSession.create(users(:test_user))
    get :show
    assert_response :success
  end

  test "should get edit" do
    UserSession.create(users(:test_user))
    get :edit, :id => users(:test_user).id
    assert_response :success
  end

  test "should update user" do
    UserSession.create(users(:test_user))
    put :update, :id => users(:test_user).id, :user => { }
    assert_redirected_to account_path
  end
end
