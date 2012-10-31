#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe PasswordResetsController do
  fixtures :all
  before(:each) do
    @tuser = FactoryGirl.create :tuser
    @tuser.password_reset_token = "random_token_asdklfjasdlfkjadf"
    @tuser.password_reset_sent_at = Time.zone.now
    mock_warden(nil)
  end

  describe "#create" do
    before (:each) do
      @params = { :username => @tuser.username, :email => @tuser.email }

      User.stub!(:find_by_username_and_email).and_return(@tuser)
      @tuser.stub!(:send_password_reset).and_return(true)
    end

    it "should send an email with password reset details" do
      @tuser.should_receive(:send_password_reset)
      post :create, @params
      response.should redirect_to(login_path)
    end
  end

  describe "#edit" do
    before (:each) do
      User.stub!(:find_by_password_reset_token!).and_return(@tuser)
    end

    it "successfully renders password reset edit page" do
      get :edit, :id => @tuser.password_reset_token
      response.should render_template :edit
    end
  end

  describe "#update" do
    before (:each) do
      @new_password = "mynewpassword"
      @params = {:id => @tuser.password_reset_token, :user => {:password => @new_password, :password_confirmation => @new_password}}

      User.stub!(:find_by_password_reset_token!).and_return(@tuser)
      @tuser.stub!(:update_attributes).and_return true
    end

    it "should update the user's password and reset the token details" do
      @tuser.should_receive(:update_attributes).
          with("password" => @new_password, "password_confirmation" => @new_password, "password_reset_token" => nil, "password_reset_sent_at" => nil)
      put :update, @params
      response.should redirect_to(login_path)
    end
  end

end
