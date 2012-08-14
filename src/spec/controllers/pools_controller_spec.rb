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

describe PoolsController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  it "should provide ui to create new pool" do
     mock_warden(@admin)
     get :new
     response.should be_success
     response.should render_template("new")
  end

  it "should fail to grant access to new pool ui for unauthenticated user" do
     mock_warden(nil)
     get :new
     response.should_not be_success
  end

  it "should provide means to create new pool" do
     mock_warden(@admin)
     lambda do
       post :create, :pool => {
         :name => 'foopool',
         :pool_family_id => PoolFamily.find_by_name('default').id,
         :enabled => true
       }
     end.should change(Pool, :count).by(1)
     response.should redirect_to(pools_path)
  end

  it "should allow RESTful delete of a single pool" do
    mock_warden(@admin)
    lambda do
      post :create, :pool => {
          :name => 'pool1',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    pool = Pool.find_by_name('pool1')
    lambda do
      delete :destroy, :id => pool.id
    end.should change(Pool, :count).by(-1)
  end

  it "should allow RESTful delete of multiple pools" do
    mock_warden(@admin)
    lambda do
      post :create, :pool => {
          :name => 'pool1',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    lambda do
      post :create, :pool => {
          :name => 'pool2',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    pool1 = Pool.find_by_name('pool1')
    pool2 = Pool.find_by_name('pool2')
    lambda do
      delete :destroy, :ids => [pool1.id, pool2.id]
    end.should change(Pool, :count).by(-2)
  end

  context "unauthenticated JSON responses " do
    before do
      accept_json
      mock_warden(nil)
    end

    it "should return 401" do
      get :index
      response.response_code.should == 401
    end
  end

  context "API" do
    render_views

    before do
      accept_xml
      mock_warden(@admin)
      @test_pool_name = "testpool1"
      @pool_family = FactoryGirl.create :pool_family
    end

    def assert_pool_api_success_response(name, familyName, familyId, quota, enabled)
      response.should be_success
      response.should have_content_type("application/xml")
      response.body.should be_xml
      xml = Nokogiri::XML(response.body)
      xml.xpath("/pool/name").text.should == name
      xml.xpath("/pool/pool_family").text.should == familyName
      xml.xpath("/pool/pool_family/@id").text.should == "#{familyId}"
      xml.xpath("/pool/quota").text.should == quota
      xml.xpath("/pool/enabled").text.should == enabled
    end

    describe "#create" do

      it "post with all expected params" do
        xmldata = "
        <pool>
          <name>#{@test_pool_name}</name>
          <pool_family_id>#{@pool_family.id}</pool_family_id>
          <enabled>true</enabled>
          <quota>
            <maximum_running_instances>1001</maximum_running_instances>
          </quota>
        </pool>"
        post :create, Hash.from_xml(xmldata)

        assert_pool_api_success_response(@test_pool_name,
                                         @pool_family.name,
                                         @pool_family.id,
                                         "1001",
                                         "true")
      end

      it "post missing pool family parameter should result in error message" do
        xmldata = "
        <pool>
          <name>#{@test_pool_name}</name>
          <!--<pool_family_id>#{@pool_family.id}</pool_family_id>-->
          <enabled>true</enabled>
          <quota>
            <maximum_running_instances>1001</maximum_running_instances>
          </quota>
        </pool>"
        post :create, Hash.from_xml(xmldata)

        response.status.should be_eql(400) # Bad Request
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/errors/error/message").text.should == "Pool family can't be blank"
      end

    end

    describe "#show" do

      it "show an existing pool" do
        @pool = FactoryGirl.create :pool

        get :show, :id => @pool.id

        assert_pool_api_success_response(@pool.name,
                                         @pool.pool_family.name,
                                         @pool.pool_family.id,
                                         "#{@pool.quota.maximum_running_instances}",
                                         "#{@pool.enabled}")
      end

      it "show a missing pool" do
        get :show, :id => -1

        response.status.should be_eql(404)
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/error/message").text.should == "Couldn't find Pool with id=-1"
      end

    end

    describe "#update" do

      it "update with all expected params" do
        # we will receive unlimited quota if
        # maximum_running_instances is not specified
        # <quota></quota> denotes unlmited quota
        xmldata = "
        <pool>
          <name>#{@test_pool_name}</name>
          <pool_family_id>#{@pool_family.id}</pool_family_id>
          <enabled>true</enabled>
        </pool>"
        post :create, Hash.from_xml(xmldata)

        assert_pool_api_success_response(@test_pool_name,
                                         @pool_family.name,
                                         @pool_family.id,
                                         "", #unlimited
                                         "true")

        xml = Nokogiri::XML(response.body)
        pool_id = xml.xpath("/pool/@id").text

        xmldata = "
        <pool>
          <name>pool-updated</name>
          <pool_family_id>#{@pool_family.id}</pool_family_id>
          <enabled>false</enabled>
          <quota>
            <maximum_running_instances>1002</maximum_running_instances>
          </quota>
        </pool>"
        put :update, :id => pool_id, :pool => Hash.from_xml(xmldata)["pool"]

        assert_pool_api_success_response("pool-updated",
                                         @pool_family.name,
                                         @pool_family.id,
                                         "1002",
                                         "false")
      end

      it "update missing pool" do
        xmldata = "<pool><name>missing-pool</name></pool>"
        put :update, :id => -1, :pool => Hash.from_xml(xmldata)["pool"]

        response.status.should be_eql(404)
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/error/message").text.should == "Couldn't find Pool with id=-1"
      end

      it "update with blank name" do
        @pool = FactoryGirl.create :pool
        xmldata = "<pool><name></name></pool>"
        put :update, :id => @pool.id, :pool => Hash.from_xml(xmldata)["pool"]

        response.status.should be_eql(400)
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/errors/error/message").text.should == "Name can't be blank"
      end

    end

  end


  context "JSON format responses for " do
    before do
      accept_json
      mock_warden(@admin)
    end

    describe "#create" do
      before do
        @pool_attributes = Factory.attributes_for(:pool)
        post :create, :pool => @pool_attributes
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["name"].should == @pool_attributes[:name] }
      it { ActiveSupport::JSON.decode(response.body)["enabled"].should == @pool_attributes[:enabled] }
    end

    describe "#destroy" do
      before do
        @pool = Factory.build(:pool)
        @tpool = Factory.build(:tpool)
        @pool.save!
        @tpool.save!
        Pool.stub!(:find).and_return([@pool], @tpool)
        delete :multi_destroy, :pools_selected => [@pool.id], :format => :json
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["success"].should == [@pool.name] }
    end
  end
end
