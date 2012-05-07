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

  shared_examples_for "http OK" do
    context "response status code" do
      subject { response.status }
      it { should be_eql(200) }
    end
  end

  shared_examples_for "http Not Found" do
    context "response status code" do
      subject { response.status }
      it { should be_eql(404) }
    end
  end

  shared_examples_for "responding with XML" do
    context "response" do
      subject { response }

      it { should have_content_type("application/xml") }

      context "body" do
        subject { response.body }
        it { should be_xml }
      end
    end
  end

  shared_examples_for "having XML with providers" do
    # TODO: implement more attributes checks
    subject { Nokogiri::XML(response.body) }
    context "list of providers" do
      #let(:xml_providers) { [subject['providers']['provider']].flatten.compact }
      let(:xml_providers) { subject.xpath('//providers/provider') }
      context "number of providers" do
        it { xml_providers.size.should be_eql(number_of_providers) }
      end
      it "should have correct providers" do
        providers.each do |provider|
          xml_provider = xml_providers.xpath("//provider[@id=\"#{provider.id}\"]")
          xml_provider.xpath('name').text.should be_eql(provider.name.to_s)
          xml_provider.xpath('@href').text.should be_eql(api_provider_url(provider))
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
            # really stub this method?
            ProvidersController.stub(:load_providers).and_return(providers)
            get :index
          end

          context "when there are 3 providers" do

            let(:providers) { 3.times{ FactoryGirl.create(:mock_provider) }; Provider.all }

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 3 }
              it_behaves_like "having XML with providers"
            end

          end

          context "when there is 1 provider" do

            let(:providers) { FactoryGirl.create(:mock_provider); Provider.all }

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 1 }
              it_behaves_like "having XML with providers"
            end

          end

          context "when there are no providers" do

            let(:providers) { Provider.all }

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            context "XML body" do
              let(:number_of_providers) { 0 }
              it_behaves_like "having XML with providers"
            end

          end
        end # #index

        describe "#show" do
          context "when requested provider exists" do

            before(:each) do
              Provider.stub(:find).and_return(provider)

              get :show, :id => 1
            end

            let(:provider) { FactoryGirl.create(:mock_provider); Provider.last }

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            context "XML body" do
              # TODO: implement more attributes checks
              subject { Hash.from_xml(response.body) }
              let(:xml_provider) { [subject['provider']].flatten.compact.first }
              it "should have correct provider" do
                xml_provider['id'].should be_eql(provider.id.to_s)
                xml_provider['href'].should be_eql(api_provider_url(provider))
              end
            end

          end # when requested provider exists

          context "when requested provider does not exist" do

            before(:each) do
              p = Provider.find_by_id(1)
              p.delete if p
              get :show, :id => 1
            end

            it_behaves_like "http Not Found"
            it_behaves_like "responding with XML"

            context "XML body" do

              subject { Nokogiri::XML(response.body) }

              it {
                subject.xpath('//error').size.should be_eql(1)
                subject.xpath('//error/code').text.should be_eql('RecordNotFound')
                subject.xpath('//error/message').text.should be_eql("Couldn't find Provider with ID=1")
              }

            end

          end
        end # #show
      end # when using admin credentials
    end # when requesting XML
  end # API
end
