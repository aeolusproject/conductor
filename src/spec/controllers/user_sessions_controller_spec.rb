#
#   Copyright 2011 Red Hat, Inc.
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
