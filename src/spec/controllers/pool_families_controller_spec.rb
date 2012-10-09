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

describe PoolFamiliesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @user_permission = FactoryGirl.create :pool_user_permission
    @user = @user_permission.user
  end

  it "should allow authorized users to create pool family" do
    mock_warden(@admin)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should change(PoolFamily, :count).by(1)
    PoolFamily.find_by_name('test').should_not be_nil
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    mock_warden(@user)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should_not change(PoolFamily, :count)
    response.should render_template('layouts/error')
  end

  it "should allow authorized users to edit pool family" do
    pool_family = FactoryGirl.create :pool_family
    mock_warden(@admin)
    family = mock_model(PoolFamily).as_null_object
    PoolFamily.stub(:find).and_return(family)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    flash[:notice].should eq(I18n.t("pool_families.flash.notice.updated"))
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    pool_family = FactoryGirl.create :pool_family
    mock_warden(@user)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    PoolFamily.find_by_name('updated pool family').should be_nil
    response.should render_template('layouts/error')
  end

  context "API" do
    render_views

    before do
      accept_xml
      mock_warden(@admin)
      @test_name = "spec-pool-family-1"
    end

    def assert_pool_api_success_response(name, quota, number_of_pools)
      response.should be_success
      response.should have_content_type("application/xml")
      response.body.should be_xml
      xml = Nokogiri::XML(response.body)
      xml.xpath("/pool_family/@id").size.should == 1
      xml.xpath("/pool_family/@href").size.should == 1
      xml.xpath("/pool_family/name").text.should == name
      xml.xpath("/pool_family/quota/@maximum_running_instances").text.should == quota
      pool_set = xml.xpath('/pool_family/pools/pool')
      pool_set.size.should be_eql(number_of_pools.to_i)
    end

    describe "#index" do

      it "get index" do
        get :index

        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        # default
        xml.xpath("/pool_families/pool_family").size.should be_eql(1)
      end
    end

    describe "#create" do
      it "post with all expected params" do
        xmldata = "
        <pool_family>
          <name>#{@test_name}</name>
          <quota maximum_running_instances='1001'></quota>
        </pool_family>"
        post :create, Hash.from_xml(xmldata)

        assert_pool_api_success_response(@test_name, "1001", 0)
      end

      it "post missing name parameter should result in error message" do
        xmldata = "
        <pool_family>
          <!--<name>#{@test_name}</name>-->
          <quota maximum_running_instances='1001'></quota>
        </pool_family>"
        post :create, Hash.from_xml(xmldata)

        response.status.should be_eql(422)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end
    end


     describe "#show" do
      it "show an existing pool family" do
        @pool_family = FactoryGirl.create :pool_family
        Aeolus::Image::Warehouse::Image.stub(:by_environment).with(@pool_family.name).and_return([])
        FactoryGirl.create(:pool, :name => "pool1", :pool_family => @pool_family)
        FactoryGirl.create(:pool, :name => "pool2", :pool_family => @pool_family)
        FactoryGirl.create(:pool, :name => "pool3", :pool_family => @pool_family)

        get :show, :id => @pool_family.id

        assert_pool_api_success_response(@pool_family.name,
                                         "#{@pool_family.quota.maximum_running_instances}",
                                         3)
      end

      it "show a missing pool family" do
        get :show, :id => -1

        response.status.should be_eql(404)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end
    end

    describe "#update" do

      it "update with all expected params" do
        Aeolus::Image::Warehouse::Image.stub(:by_environment).with("#{@test_name}").and_return([])
        xmldata = "
        <pool_family>
          <name>#{@test_name}</name>
        </pool_family>"
        post :create, Hash.from_xml(xmldata)

        assert_pool_api_success_response(@test_name, I18n.t('pools.form.unlimited'), 0)

        xml = Nokogiri::XML(response.body)
        pool_family_id = xml.xpath("/pool_family/@id").text

        xmldata = "
        <pool_family>
          <name>pool-family-updated</name>
          <quota maximum_running_instances='1002'></quota>
        </pool_family>"
        put :update, :id => pool_family_id, :pool_family => Hash.from_xml(xmldata)["pool_family"]

        assert_pool_api_success_response("pool-family-updated", "1002", 0)
      end

      it "update missing pool family" do
        xmldata = "<pool_family><name>missing-pool</name></pool_family>"
        put :update, :id => -1, :pool_family => Hash.from_xml(xmldata)["pool_family"]

        response.status.should be_eql(404)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end

      it "update with blank name" do
        @pool_family = FactoryGirl.create :pool_family
        xmldata = "<pool_family><name></name></pool_family>"
        put :update, :id => @pool_family.id, :pool_family => Hash.from_xml(xmldata)["pool_family"]

        response.status.should be_eql(422)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end
    end

    describe "#destroy" do

      it "delete an existing pool family" do
        @pool_family = FactoryGirl.create :pool_family
        PoolFamily.any_instance.stub(:images).and_return([])
        get :destroy, :id => @pool_family.id

        response.status.should be_eql(200)
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/pool_family/@id").text.should == "#{@pool_family.id}"
        xml.xpath("/pool_family/status").text.should == "DELETED"
      end

      it "delete a missing pool family should throw error" do
        get :destroy, :id => -1

        response.status.should be_eql(404)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end

      it "delete default pool family should throw error" do
        @pool_family = FactoryGirl.create :pool_family
        get :destroy, :id => 1

        response.status.should be_eql(500)
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end
    end
  end
end
