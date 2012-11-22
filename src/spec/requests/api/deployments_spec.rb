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
    subject { Nokogiri::XML(response.body) }

    context "number of deployments" do
      it { subject.xpath("/deployments/deployment").size.should == deployments.size }
    end

    context "deployment elements data" do
      it "is printed correctly" do
        deployments.each do |deployment|
          xml_deployment = subject.xpath("/deployments/deployment[@id=\"#{deployment.id}\"]")
          xml_deployment.size.should == 1
          xml_deployment.xpath("@href").text.should == api_deployment_url(deployment)
        end
      end
    end
  end

  shared_examples_for "showing deployment details in XML" do
    context "deployment details" do
      subject { Nokogiri::XML(response.body).xpath("/deployment") }

      it "is printed correctly" do
        subject.size.should == 1
        subject.xpath("@id").text.should == deployment.id.to_s
        subject.xpath("@href").text.should == api_deployment_url(deployment)
        subject.xpath("name").text.should == deployment.name
        subject.xpath("pool/@id").text.should == deployment.pool.id.to_s
        subject.xpath("pool/@href").text.should == api_pool_url(deployment.pool)
        # TODO: implement when frontend realms are available via API
        # subject.xpath("frontend_realm/@id").text.should == deployment.frontend_realm.id.to_s
        # subject.xpath("frontend_realm/@href").text.should == api_frontend_realm_url(deployment.frontend_realm)
        subject.xpath("uuid").text.should == deployment.uuid

        # TODO implement and test these once it's clear how states should be represented,
        # what date/time format to use etc.:
        # subject.xpath("state").text.should
        # subject.xpath("created_at").text.should
        # subject.xpath("updated_at").text.should
        # subject.xpath("uptime_1st_instance_running").text.should
        # subject.xpath("global_uptime").text.should
        # subject.xpath("scheduled_for_deletion").text.should
        # subject.xpath("deployable-xml").text.should
        # subject.xpath("history").text.should
        # subject.xpath("instances/instance").count.should
        # subject.xpath("instances/instance").each...
        # subject.xpath("user[@rel=owner]")
      end
    end
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
      Factory.create(:deployment, {
        :pool => Pool.first,
        :owner => @user,
        :frontend_realm => Factory.create(:frontend_realm)
      })
    }

    before :each do
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
