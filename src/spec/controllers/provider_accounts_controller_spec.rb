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

describe ProviderAccountsController do

  render_views

  shared_examples_for "having XML with provider accounts" do
    # TODO: implement more attributes checks
    subject { Nokogiri::XML(response.body) }
    context "list of provider accounts" do
      #let(:xml_provider_accounts) { [subject['provider_accounts']['provider_account']].flatten.compact }
      let(:xml_provider_accounts) { subject.xpath('//provider_accounts/provider_account') }
      context "number of provider accounts" do
        it { xml_provider_accounts.size.should be_eql(number_of_provider_accounts) }
      end
      it "should have correct provider accounts" do
        provider_accounts.each do |provider_account|
          xml_provider_account = xml_provider_accounts.xpath("//provider_account[@id=\"#{provider_account.id}\"]")
          xml_provider_account.xpath('name').text.should be_eql(provider_account.name.to_s)
          xml_provider_account.xpath('@href').text.should be_eql(api_provider_account_url(provider_account))
        end
      end
      it "should have not incorrect provider accounts" do
        other_provider_accounts.each do |provider_account|
          xml_provider_account = xml_provider_accounts.xpath("//provider_account[@id=\"#{provider_account.id}\"]")
          xml_provider_account.should be_empty
        end
      end
    end
  end

  context "UI" do

    fixtures :all
    before(:each) do
      @tuser = FactoryGirl.create :tuser
      @provider_account = FactoryGirl.create :mock_provider_account
      @provider = @provider_account.provider

      @admin_permission = Permission.create :role => Role.find(:first, :conditions => ['name = ?', 'base.provider.admin']),
        :permission_object => @provider,
        :entity => FactoryGirl.create(:provider_admin_user).entity
      @admin = @admin_permission.user
    end

    it "shows provider accounts as XML list" do
      mock_warden(@admin)
      get :index, :format => :xml
      response.should be_success

      # it should have not provider accounts credentials
      resp = Hash.from_xml(response.body)
      resp['provider_accounts']['provider_account']['provider_credentials'].should be_nil
    end

    it "doesn't allow to save provider's account if not valid credentials" do
      mock_warden(@admin)
      post :create, :provider_account => {:provider_id => @provider.id, :credentials_hash => {}}, :provider_id => @provider.id
      response.should be_success
      response.should render_template("new")
      request.flash[:error].should == "Cannot add the provider account."
    end

    it "should permit users with account modify permission to access edit cloud account interface" do
      mock_warden(@admin)
      get :edit, :provider_id => @provider, :id => @provider_account.id
      response.should be_success
      response.should render_template("edit")
    end

    it "should allow users with account modify password to update a cloud account" do
      mock_warden(@admin)
      @provider_account.credentials_hash = {:username => 'mockuser2', :password => "foobar"}
      @provider_account.stub!(:valid_credentials?).and_return(true)
      @provider_account.quota = Quota.new
      @provider_account.save.should be_true
      post :update, :id => @provider_account.id, :provider_account => { :credentials_hash => {:username => 'mockuser', :password => 'mockpassword'} }
      response.should redirect_to edit_provider_path(@provider_account.provider_id, :details_tab => 'accounts')
      ProviderAccount.find(@provider_account.id).credentials_hash['password'].should == "mockpassword"
    end

    it "should allow users with account modify permission to delete a cloud account" do
      mock_warden(@admin)
      lambda do
        post :multi_destroy, :provider_id => @provider_account.provider_id, :accounts_selected => [@provider_account.id]
      end.should change(ProviderAccount, :count).by(-1)
      response.should redirect_to edit_provider_path(@provider_account.provider_id, :details_tab => 'accounts')
      ProviderAccount.find_by_id(@provider_account.id).should be_nil
    end

    describe "should deny access to users without account modify permission" do
      before do
        mock_warden(@tuser)
      end

      it "for edit" do
        get :edit, :provider_id => @provider_account.provider_id, :id => @provider_account.id
        response.should render_template('layouts/error')
      end

      it "for update" do
        post :update, :id => @provider_account.id, :provider_account => { :password => 'foobar' }
        response.should render_template('layouts/error')
      end

      it "for destroy" do
        post :destroy, :id => @provider_account.id
        response.should render_template('layouts/error')
      end
    end

    it "should provide ui to create new account" do
      mock_warden(@admin)
      get :new, :provider_id => @provider.id
      response.should be_success
      response.should render_template("new")
    end

    it "should fail to grant access to account UIs for unauthenticated user" do
      mock_warden(nil)
      get :new
      response.should_not be_success
    end

  end # UI

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

          context "with parent provider specified" do

            before(:each) do
              # call these to create them in database
              provider_accounts
              other_provider_accounts

              get :index, :provider_id => provider.id
            end

            let(:provider) { FactoryGirl.create(:mock_provider) }
            let(:other_provider) { FactoryGirl.create(:mock_provider) }
            let(:other_provider_accounts) do
              3.times do
                pa = FactoryGirl.build(:mock_provider_account_seq, :provider => other_provider)
                pa.stub!(:validate_credentials).and_return(true)
                pa.save
              end
              other_provider.provider_accounts
            end

            context "when there are 3 provider accounts for specified provider" do

              let(:provider_accounts) do
                3.times do
                  pa = FactoryGirl.build(:mock_provider_account_seq, :provider => provider)
                  pa.stub!(:validate_credentials).and_return(true)
                  pa.save
                end
                provider.provider_accounts
              end

              it_behaves_like "http OK"
              it_behaves_like "responding with XML"

              context "XML body" do
                let(:number_of_provider_accounts) { 3 }
                it_behaves_like "having XML with provider accounts"
              end
            end

          end

          context "with parent provider not specified" do

            before(:each) do
              # call these to create them in database
              provider_accounts
              other_provider_accounts

              get :index
            end

            let(:provider) { FactoryGirl.create(:mock_provider) }
            let(:other_provider) { FactoryGirl.create(:mock_provider) }
            let(:other_provider_accounts) { [] }

            context "when there are 3 provider accounts for specified provider" do

              let(:provider_accounts) do
                3.times do
                  pa = FactoryGirl.build(:mock_provider_account_seq, :provider => provider)
                  pa.stub!(:validate_credentials).and_return(true)
                  pa.save
                end

                3.times do
                  pa = FactoryGirl.build(:mock_provider_account_seq, :provider => other_provider)
                  pa.stub!(:validate_credentials).and_return(true)
                  pa.save
                end
                other_provider.provider_accounts + provider.provider_accounts
              end

              it_behaves_like "http OK"
              it_behaves_like "responding with XML"

              context "XML body" do
                let(:number_of_provider_accounts) { 6 }
                it_behaves_like "having XML with provider accounts"
              end
            end

          end
        end # #index

        describe "#destroy" do
          before(:each) do
            @provider_account = FactoryGirl.create(:mock_provider_account)
          end

          it "when requested provider account exists" do
            ProviderAccount.stub(:find).and_return(@provider_account)
            get :destroy, :id => @provider_account.id
            response.status.should be_eql(200)
            response.should have_content_type("application/xml")
            response.body.should be_xml
            subject = Nokogiri::XML(response.body)
            xml_provider_account = subject.xpath("//provider_account[@id=\"#{@provider_account.id}\"]")
            xml_provider_account.xpath('@id').text.strip.should == "#{@provider_account.id}"
            xml_provider_account.xpath('status').text.strip.should == "DELETED"
          end

          it "when requested provider account doesn't exists" do
            ProviderAccount.stub(:find).and_return(nil)
            get :destroy, :id => "id_that_does_not_exist"
            response.status.should be_eql(404)
            response.should have_content_type("application/xml")
            response.body.should be_xml
            subject = Nokogiri::XML(response.body)
            subject.xpath('//error/code').text.strip.should == "ProviderAccountNotFound"
          end
        end #destroy
      end

    end

  end
end
