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

describe Api::EntrypointController do
  render_views

  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  context "XML format response for " do
    before do
      send_and_accept_xml
    end

    describe "#index" do
      before do
        get :index
      end

      it { response.should be_success }
      it { response.headers['Content-Type'].should include("application/xml") }
      it "should have all resources URLs" do
        resp = Hash.from_xml(response.body)
        api = resp['api']
        api['builds']['href'].should == api_builds_url
        api['catalogs']['href'].should == api_catalogs_url
        api['images']['href'].should == api_images_url
        api['pools']['href'].should == api_pools_url
        api['pool_families']['href'].should == api_pool_families_url
        api['providers']['href'].should == api_providers_url
        api['provider_accounts']['href'].should == api_provider_accounts_url
        api['provider_images']['href'].should == api_provider_images_url
        api['provider_realms']['href'].should == api_provider_realms_url
        api['target_images']['href'].should == api_target_images_url
      end
    end
  end
end
