require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  fixtures :users
  test "should get new" do
    get :login
    assert_response :success
  end

  test "should create user session" do
    post :create, :user_session => { :login => "tuser", :password => "testpass" }
    assert user_session = UserSession.find
    assert_equal users(:test_user), user_session.user
    assert_redirected_to account_path
  end

  test "should destroy user session" do
    post :create, :user_session => { :login => "tuser", :password => "testpass" }
    delete :logout
    assert_nil UserSession.find
    assert_redirected_to login_path
  end
end
