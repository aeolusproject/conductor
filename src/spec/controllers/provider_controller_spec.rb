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

describe ProvidersController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :provider_admin_permission
    @provider = @admin_permission.permission_object
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  describe "provide ui to view realms" do
    before do
      get :show, :id => @provider.id, :details_tab => 'realms', :format => :js
    end

    it { response.should be_success }
    it { assigns[:realm_names].size.should == @provider.realms.size }
    it { response.should render_template(:partial => "providers/_realms") }
  end

  describe "check availability" do
    context "when provider is not accessible" do
      before do
        @provider.update_attribute(:url, "invalid_url")
      end

      it "should update availability status on test connection" do
        @provider.available.should_not be_false
        get :edit, :id => @provider.id, :test_provider => true
        @provider.reload
        @provider.available.should be_false
      end
    end
  end
end
