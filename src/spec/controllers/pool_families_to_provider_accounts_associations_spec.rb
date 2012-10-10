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

describe PoolFamiliesToProviderAccountsAssociationsController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @user_permission = FactoryGirl.create :pool_family_user_permission
    @user = @user_permission.user
  end

  context "API" do

    before do
      accept_xml
      mock_warden(@admin)
    end

    describe "#index" do
      render_views
      it "show list of associated provider accounts" do
        @pool_family = FactoryGirl.create :pool_family
        @provider_account = FactoryGirl.create :mock_provider_account
        @provider_account2 = FactoryGirl.create :mock_provider_account
        @pool_family.provider_accounts << @provider_account
        @pool_family.provider_accounts << @provider_account2

        post :index, :pool_family_id => @pool_family.id

        response.status.should be_eql(200)
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)
        xml.xpath("/provider_accounts/provider_account").size.should be_eql(2)
        xml.xpath("/provider_accounts/provider_account[@id=#{@provider_account.id}]/@href").text.should == api_provider_account_url(@provider_account.id)
      end
    end

    describe "#show" do
      before do
        @pool_family = FactoryGirl.create :pool_family
        @provider_account = FactoryGirl.create :mock_provider_account
        @pool_family.provider_accounts << @provider_account
      end

      it "an association that exists" do
        post :show, :id => @provider_account.id, :pool_family_id => @pool_family.id
        response.status.should be_eql(204)
      end

      it "an association that does not exist" do
        post :show, :id => -1, :pool_family_id => @pool_family.id
        response.status.should be_eql(404)
      end

    end


    describe "#update" do
      it "create the association" do
        @pool_family = FactoryGirl.create :pool_family
        @provider_account = FactoryGirl.create :mock_provider_account
        @pool_family.provider_accounts.where(:id => @provider_account.id).should be_empty

        post :update, :id => @provider_account.id, :pool_family_id => @pool_family.id

        response.status.should be_eql(204)
        @pool_family.provider_accounts.where(:id => @provider_account.id).size.should == 1

        # try creating it a second time
        post :update, :id => @provider_account.id, :pool_family_id => @pool_family.id

        response.status.should be_eql(204)
      end

      it "create an association for a provider account that does not exist" do
        @pool_family = FactoryGirl.create :pool_family

        post :update, :id => -1, :pool_family_id => @pool_family.id

        response.status.should be_eql(404)
      end

    end

    describe "#destroy" do
      before do
        @pool_family = FactoryGirl.create :pool_family
        @provider_account = FactoryGirl.create :mock_provider_account
      end

      it "remove the association" do
        @pool_family.provider_accounts << @provider_account
        @pool_family.provider_accounts.where(:id => @provider_account.id).size.should == 1

        post :destroy, :id => @provider_account.id, :pool_family_id => @pool_family.id

        response.status.should be_eql(204)
        @pool_family.provider_accounts.where(:id => @provider_account.id).should be_empty

        # removing it again should result in 204
        post :destroy, :id => @provider_account.id, :pool_family_id => @pool_family.id

        response.status.should be_eql(204)
      end

      it "remove the association that does not exist" do
        @pool_family.provider_accounts.where(:id => @provider_account.id).size.should == 0

        post :destroy, :id => -1, :pool_family_id => @pool_family.id

        response.status.should be_eql(404)
      end
    end


  end
end
