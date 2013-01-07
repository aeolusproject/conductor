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

describe "Deployments API" do
  shared_examples_for "listing deployments in XML" do
    subject { Nokogiri::XML(response.body).xpath("/deployments") }

    context "collection URL" do
      it do
        collection_url = defined?(pool) ? api_pool_deployments_url(pool) : api_deployments_url
        subject.xpath("@href").text.should == collection_url
      end
    end

    context "number of deployments" do
      it { subject.xpath("deployment").size.should == deployments.size }
    end

    context "deployment elements data" do
      it "is printed correctly" do
        deployments.each do |deployment|
          xml_deployment = subject.xpath("deployment[@id=\"#{deployment.id}\"]")
          xml_deployment.size.should == 1
          check_deployment_xml_fields(xml_deployment, deployment)
        end
      end
    end
  end

  shared_examples_for "showing deployment details in XML" do
    context "deployment details" do
      subject { Nokogiri::XML(response.body).xpath("/deployment") }

      it "is printed correctly" do
        subject.size.should == 1
        check_deployment_xml_fields(subject, deployment)
      end
    end
  end

  def check_deployment_xml_fields(xml_deployment, deployment)
    api_helper = Object.new.extend(ApiHelper)

    xml_deployment.xpath("@id").text.should == deployment.id.to_s
    xml_deployment.xpath("@href").text.should == api_deployment_url(deployment)
    xml_deployment.xpath("name").text.should == deployment.name
    xml_deployment.xpath("pool/@id").text.should == deployment.pool.id.to_s
    xml_deployment.xpath("pool/@href").text.should == api_pool_url(deployment.pool)
    # TODO: implement when frontend realms are available via API
    # xml_deployment.xpath("frontend_realm/@id").text.should == deployment.frontend_realm.id.to_s
    # xml_deployment.xpath("frontend_realm/@href").text.should == api_frontend_realm_url(deployment.frontend_realm)
    xml_deployment.xpath("uuid").text.should == deployment.uuid
    xml_deployment.xpath("scheduled_for_deletion").text.should == deployment.scheduled_for_deletion.to_s
    xml_deployment.xpath("uptime_1st_instance").text.should ==
      api_helper.xmlschema_absolute_duration(deployment.uptime_1st_instance)
    xml_deployment.xpath("uptime_all").text.should ==
      api_helper.xmlschema_absolute_duration(deployment.uptime_all)
    xml_deployment.xpath("deployable_xml").inner_html.should == deployment.deployable_xml.to_s

    # TODO implement and test these
    # xml_deployment.xpath("state").text.should
    # xml_deployment.xpath("instances/instance").count.should
    # xml_deployment.xpath("instances/instance").each...
    # xml_deployment.xpath("user[@rel=owner]")
  end

  let(:headers) { {
    'HTTP_ACCEPT' => 'application/xml',
    'CONTENT_TYPE' => 'application/xml'
  } }

  before :each do
    @user = FactoryGirl.create(:admin_permission).user
    login_as(@user)
  end

  describe "GET /api/deployments" do
    let!(:deployments) {
      deployments = []
      2.times { deployments << Factory.create(:deployment, {:pool => Pool.first, :owner => @user}) }
      deployments
    }

    before :each do
      get '/api/deployments', nil, headers
    end

    it_behaves_like "http OK"
    it_behaves_like "responding with XML"
    it_behaves_like "listing deployments in XML"
  end

  describe "GET /api/deployments/:id" do
    let!(:deployment) {
      deployment = Factory.create(:deployment, {
        :pool => Pool.first,
        :owner => @user,
        :frontend_realm => Factory.create(:frontend_realm),
        :deployable_xml => '<deployable name="mock deployable"></deployable>',
      })
      deployment.stub(:uptime_1st_instance).and_return(40)
      deployment.stub(:uptime_all).and_return(10)
      deployment
    }

    before :each do
      Deployment.stub(:find).with(deployment.id.to_s).and_return(deployment)
      get "/api/deployments/#{deployment.id}", nil, headers
    end

    it_behaves_like "http OK"
    it_behaves_like "responding with XML"
    it_behaves_like "showing deployment details in XML"
  end

  describe "GET /api/pools/:pool_id/deployments" do
    let!(:unlisted_deployments) do
      Factory.create(:deployment, {:pool => Pool.first, :owner => @user})
    end
    let!(:pool) {
      Factory.create(:pool)
    }
    let!(:deployments) {
      deployments = []
      2.times { deployments << Factory.create(:deployment, {:pool => pool, :owner => @user}) }
      deployments
    }

    before :each do
      get "/api/pools/#{pool.id}/deployments", nil, headers
    end

    it_behaves_like "http OK"
    it_behaves_like "responding with XML"
    it_behaves_like "listing deployments in XML"
  end
end
