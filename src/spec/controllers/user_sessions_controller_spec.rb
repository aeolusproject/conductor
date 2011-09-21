#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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
