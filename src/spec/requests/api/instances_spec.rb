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
      @instance = FactoryGirl.create(:mock_running_instance)
      @instance.instance_key = FactoryGirl.create :mock_instance_key, :instance => @instance
      @instance.instance_key.should_not be_nil
    end

    describe "#index" do

      it "get index" do
        get "/api/instances", nil, headers

        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/instances/instance").size.should > 0
        xml.xpath("/instances/instance[@id='#{@instance.id}']/@href").
          text.should == api_instance_url(@instance.id)
      end
    end

    describe "#show" do

      it "show instance" do
        get "/api/instances/#{@instance.id}", nil, headers
        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/instance/@id").text.should == @instance.id.to_s
        xml.xpath("/instance/@href").text.should == api_instance_url(@instance)
        xml.xpath("/instance/name").text.should == @instance.name
        xml.xpath("/instance/external_key").text.should == @instance.external_key
        xml.xpath("/instance/state").text.should == @instance.state
        xml.xpath("/instance/hardware_profile[@id='#{@instance.hardware_profile.id}']/@href").
          text.should == api_hardware_profile_url(@instance.hardware_profile)
        xml.xpath("/instance/owner_id").text.should == @instance.owner_id.to_s
        xml.xpath("/instance/pool[@id='#{@instance.pool.id}']/@href").
          text.should == api_pool_url(@instance.pool)
        xml.xpath("/instance/provider_account[@id='#{@instance.provider_account.id}']/@href").
          text.should == api_provider_account_url(@instance.provider_account)
        xml.xpath("/instance/public_addresses").text.should == @instance.public_addresses
        xml.xpath("/instance/private_addresses").text.should == @instance.private_addresses
        xml.xpath("/instance/created_at").
          text.should == @instance.created_at.strftime("%Y-%m-%d %H:%M:%S UTC")
        xml.xpath("/instance/updated_at").
          text.should == @instance.updated_at.strftime("%Y-%m-%d %H:%M:%S UTC")
        # TODO xml should not be quoted
        #xml.xpath("/instance/assembly_xml").text.should == @instance.assembly_xml
        xml.xpath("/instance/instance_config_xml").text.should == @instance.instance_config_xml.to_s
        xml.xpath("/instance/image_uuid").text.should == @instance.image_uuid.to_s
        xml.xpath("/instance/image_build_uuid").text.should == @instance.image_build_uuid.to_s
        xml.xpath("/instance/provider_image_uuid").text.should == @instance.provider_image_uuid.to_s
        xml.xpath("/instance/provider_instance_id").text.should == @instance.provider_instance_id.to_s
        xml.xpath("/instance/user_data").text.should == @instance.user_data.to_s
        xml.xpath("/instance/ssh_key/@href").
          text.should == key_instance_url(@instance.instance_key)
        xml.xpath("/instance/ssh_key_name").text.should == @instance.instance_key.name
        xml.xpath("/instance/history/entry").size.should > 0
        xml.xpath("/instance/history/entry/time").
          text.should == @instance.events.first.event_time.strftime("%Y-%m-%d %H:%M:%S UTC")
        xml.xpath("/instance/history/entry/message").text.should == @instance.events.first.summary
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
