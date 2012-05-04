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

  render_views

  shared_examples_for "responding with XML" do
    context "response" do
      subject { response }

      it { should be_success }
      it { should have_content_type("application/xml") }

      context "body" do
        subject { response.body }
        it { should be_xml }
      end
    end
  end

  shared_examples_for "having XML with providers" do
    # TODO: implement more attributes checks
    subject { Hash.from_xml(response.body) }
    context "list of providers" do
      let(:xml_providers) { [subject['providers']['provider']].flatten.compact }
      context "number of providers" do
        it { xml_providers.size.should be_eql(number_of_providers) }
      end
      it "should have correct providers" do
        providers.each do |provider|
          xml_provider = xml_providers.find{|xp| xp['name'] == provider.name}
          xml_provider['id'].should be_eql(provider.id.to_s)
          xml_provider['href'].should be_eql(api_provider_url(provider))
        end
      end
    end
  end

  context "UI" do

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

  context "API" do
    context "when requesting XML" do

      before(:each) do
        accept_xml
      end

      context "when using admin credentials" do
        before(:each) do
          user = FactoryGirl.create(:admin_permission).user
          mock_warden(user)
        end

        describe "#index" do

          before(:each) do
            ProvidersController.stub(:load_providers).and_return(providers)
            get :index
          end

          context "when there are 3 providers" do

            let(:providers) { 3.times{ FactoryGirl.create(:mock_provider) }; Provider.all }

            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 3 }
              it_behaves_like "having XML with providers"
            end

          end

          context "when there is 1 provider" do

            let(:providers) { FactoryGirl.create(:mock_provider); Provider.all }

            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 1 }
              it_behaves_like "having XML with providers"
            end

          end

          context "when there are no providers" do

            let(:providers) { Provider.all }

            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 0 }
              it_behaves_like "having XML with providers"
            end

          end
        end
      end
    end
  end
end
