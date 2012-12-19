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

describe "Instances" do
  let(:headers) { {
      'HTTP_ACCEPT' => 'application/xml',
      'CONTENT_TYPE' => 'application/xml'
    } }

  context "API" do
    before(:each) do
      user = FactoryGirl.create(:admin_permission).user
      login_as(user)
      @instance = FactoryGirl.create(:mock_running_instance, :instance_config_xml => "<instance-config id='some-test-id'>some-test-data</instance-config>")
      @instance.instance_key = FactoryGirl.create :mock_instance_key, :instance => @instance
      @instance.instance_key.should_not be_nil
    end

    def check_instance_xml(xml_instance, instance)
      api_helper = Object.new.extend(ApiHelper)

      xml_instance.xpath("@id").text.should == instance.id.to_s
      xml_instance.xpath("@href").text.should == api_instance_url(instance)
      xml_instance.xpath("name").text.should == instance.name
      xml_instance.xpath("external_key").text.should == instance.external_key
      #xml_instance.xpath("state").text.should == instance.state
      xml_instance.xpath("hardware_profile[@id='#{instance.hardware_profile.id}']/@href").
        text.should == api_hardware_profile_url(instance.hardware_profile)
      # TODO: users api endpoint
      #xml_instance.xpath("owner_id").text.should == instance.owner_id.to_s
      xml_instance.xpath("pool[@id='#{instance.pool.id}']/@href").
        text.should == api_pool_url(instance.pool)
      xml_instance.xpath("deployment[@id='#{instance.deployment.id}']/@href").
        text.should == api_deployment_url(instance.deployment)
      xml_instance.xpath("provider_account[@id='#{instance.provider_account.id}']/@href").
        text.should == api_provider_account_url(instance.provider_account)
      xml_instance.xpath("public_addresses").text.should == instance.public_addresses
      xml_instance.xpath("private_addresses").text.should == instance.private_addresses
      xml_instance.xpath("created_at").
        text.should == api_helper.xmlschema_datetime(instance.created_at)
      xml_instance.xpath("updated_at").
        text.should == api_helper.xmlschema_datetime(instance.updated_at)
      xml_instance.xpath("assembly_xml").inner_html.
        should== instance.assembly_xml.to_s
      xml_instance.xpath("instance_config_xml").inner_html.
        should == instance.instance_config_xml.to_s
      # TODO: point to resource url after Tim integration
      #xml_instance.xpath("image_uuid").text.should == instance.image_uuid.to_s
      #xml_instance.xpath("image_build_uuid").text.should == instance.image_build_uuid.to_s
      #xml_instance.xpath("provider_image_uuid").text.should == instance.provider_image_uuid.to_s
      #xml_instance.xpath("provider_instance_id").text.should == instance.provider_instance_id.to_s
      xml_instance.xpath("user_data").text.should == instance.user_data.to_s
      xml_instance.xpath("ssh_key/@href").
        text.should == key_instance_url(instance.instance_key)
      xml_instance.xpath("ssh_key_name").text.should == instance.instance_key.name
      # TODO events api endpoint
      #xml_instance.xpath("history/entry").size.should > 0
      #xml_instance.xpath("history/entry/time").
      #  text.should == instance.events.first.event_time.strftime("%Y-%m-%d %H:%M:%S UTC")
      #xml_instance.xpath("history/entry/message").text.should == instance.events.first.summary
    end

    describe "#index" do

      it "get index" do
        get "/api/instances", nil, headers

        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/instances/instance").size.should > 0
        xml.xpath("/instances/instance").size.should == Instance.all.size
        xml.xpath("/instances/@href").text.should == api_instances_url
        Instance.all.each do |instance|
          check_instance_xml(xml.xpath("/instances/instance[@id='#{instance.id}']"), instance)
        end
      end

      it "get collection of instances from deployment" do
        Instance.all.size.should_not == @instance.deployment.instances.size

        get "/api/deployments/#{@instance.deployment.id}/instances", nil, headers
        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/instances/instance").size.should > 0
        xml.xpath("/instances/instance").size.should == @instance.deployment.instances.size
        xml.xpath("/instances/@href").text.should == api_deployment_instances_url(@instance.deployment)
        @instance.deployment.instances.each do |instance|
          check_instance_xml(xml.xpath("/instances/instance[@id='#{instance.id}']"), instance)
        end
      end

    end

    describe "#show" do

      it "show instance" do
        get "/api/instances/#{@instance.id}", nil, headers
        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        check_instance_xml(xml.xpath("/instance"), @instance)
      end

      it "show nonexistent instance" do
        get "/api/instances/-1", nil, headers
        response.status.should == 404
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end

    end
  end
end
