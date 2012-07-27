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

describe HardwareProfilesController do

  render_views

  shared_examples_for "having XML with hwps" do
    # TODO: implement more attributes checks
    subject { Nokogiri::XML(response.body) }
    context "list of hardware_profiles" do
      let(:xml_hwps) { subject.xpath('//hardware_profiles/hardware_profile') }
      context "number of hardware_profiles" do
        it { xml_hwps.size.should be_eql(number_of_hardware_profiles) }
      end
      it "should have correct hardware_profiles" do
        hardware_profiles.each do |hardware_profile|
          xml_hwp = xml_hwps.xpath("//hardware_profile[@id=\"#{hardware_profile.id}\"]")
          xml_hwp.xpath('name').text.should be_eql(hardware_profile.name.to_s)
          xml_hwp.xpath('@href').text.should be_eql(hardware_profile_url(hardware_profile))
        end
      end
    end
  end

  context "UI" do
    fixtures :all
    before(:each) do
      @admin_permission = FactoryGirl.create :admin_permission
      @admin = @admin_permission.user
    end

    describe "Authorization" do

      context "Admin" do
        it "should provide ui to view all hardware profiles" do
          mock_warden(@admin)
          @request.accept = "text/html"
          get :index
          response.should be_success
          assigns[:hardware_profiles].size.should == HardwareProfile.count
          response.should render_template("index")
        end

        it "should be able to create hardware profiles" do
          mock_warden(@admin)
          lambda do
            post :create, :commit => 'Save', :hardware_profile => {
              :name => 'test',
              :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
              :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
              :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
              :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
            }
          end.should change(HardwareProfile, :count).by(1)
          HardwareProfile.find_by_name('test').should_not be_nil
          response.should redirect_to(hardware_profiles_path)
        end

        it "should be able to edit hardware profiles" do
          hardware_profile = Factory.create :hardware_profile
          mock_warden(@admin)
          put :update, :id => hardware_profile.id, :hardware_profile => {
            :name => 'updated hwp',
            :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
            :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
            :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
            :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
          }
          HardwareProfile.find_by_name('updated hwp').should_not be_nil
          response.should redirect_to(hardware_profiles_path)
        end

        it "should be able to delete hardware profiles" do
          hardware_profile = Factory.create :hardware_profile
          mock_warden(@admin)

          HardwareProfile.exists?(hardware_profile.id).should be_true
          delete :destroy, :id => hardware_profile.id
          HardwareProfile.exists?(hardware_profile.id).should be_false
          response.should redirect_to(hardware_profiles_path)
        end

      end


      context "Unauthorized user" do
        before(:each) do
          @user_permission = FactoryGirl.create :pool_user_permission
          @user = @user_permission.user
        end

        it "should not list hw profiles which I'm not allowed to see" do
          hardware_profile = Factory.create :hardware_profile
          mock_warden(@user)
          @request.accept = "text/html"
          get :index
          response.should be_success
          assigns[:hardware_profiles].find {|p| p.name == hardware_profile.name}.should be_nil
          response.should render_template("index")
        end

        it "should not be able to create hardware profiles" do
          mock_warden(@user)
          lambda do
            post :create, :commit => 'Save', :hardware_profile => {
              :name => 'test',
              :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
              :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
              :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
              :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
            }
          end.should_not change(HardwareProfile, :count)
          HardwareProfile.find_by_name('test').should be_nil
          response.should render_template('layouts/error')
        end

        it "should not be able to edit hardware profiles" do
          hardware_profile = Factory.create :hardware_profile
          mock_warden(@user)
          put :update, :id => hardware_profile.id, :hardware_profile => {
            :name => 'updated hwp',
            :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
            :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
            :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
            :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
          }
          HardwareProfile.find_by_name('updated hwp').should be_nil
          response.should render_template('layouts/error')
        end


        it "should not be able to delete hardware profiles" do
          hardware_profile = Factory.create :hardware_profile
          mock_warden(@user)

          HardwareProfile.exists?(hardware_profile.id).should be_true
          delete :destroy, :id => hardware_profile.id
          HardwareProfile.exists?(hardware_profile.id).should be_true
          response.should render_template('layouts/error')
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
           @admin_permission = FactoryGirl.create :admin_permission
           @admin = @admin_permission.user
           mock_warden(@admin)
        end

        describe "#show" do
          let(:hwp) { Factory.create(:front_hwp1) }

          context "when requested hardware profile exists" do

            before(:each) do
              get :show, :id => hwp.id
            end

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            context "XML body" do
              # TODO: implement more attributes checks
              subject { Nokogiri::XML(response.body) }
              it {
                subject.xpath("//hardware_profile/@id").text.should be_eql(hwp.id.to_s)
              }

            end
          end

          context "when requested hardware profile does not exist" do

            before(:each) do
              h = HardwareProfile.find_by_id(hwp.id)
              h.delete if h
              get :show, :id => hwp.id
            end

            it_behaves_like "http Not Found"
            it_behaves_like "responding with XML"

            context "XML body" do

              subject { Nokogiri::XML(response.body) }

              it {
                subject.xpath('//error').size.should be_eql(1)
                subject.xpath('//error/code').text.should be_eql('RecordNotFound')
              }
            end
          end
        end

        describe "#create" do
          before(:each) do
            post :create, :commit => 'Save', :hardware_profile => {
              :name => 'test',
              :memory_attributes => FactoryGirl.attributes_for(:mock_hwp1_memory),
              :cpu_attributes => FactoryGirl.attributes_for(:mock_hwp1_cpu),
              :storage_attributes => FactoryGirl.attributes_for(:mock_hwp1_storage),
              :architecture_attributes => FactoryGirl.attributes_for(:mock_hwp2_memory),
            }
          end

          context "with correct parameters" do
            let(:hwp) { FactoryGirl.build(:front_hwp2) }

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"
          end
        end

        describe "#destroy" do

          let(:hwp) { Factory.create(:front_hwp1) }

          context "existing hwp" do

            before(:each) do
              delete :destroy, :id => hwp.id
            end

            it_behaves_like "http OK"
            it_behaves_like "responding with XML"

            it { expect { hwp.reload }.to raise_error(ActiveRecord::RecordNotFound) }

          end

          context "non existing hwp" do

            before(:each) do
              hwp.delete
              delete :destroy, :id => hwp.id
            end

            it_behaves_like "http Not Found"
            it_behaves_like "responding with XML"

            context "XML body" do
              subject { Nokogiri::XML(response.body) }

              it {
                subject.xpath('//error').size.should be_eql(1)
                subject.xpath('//error/code').text.should be_eql('RecordNotFound')
              }
            end
          end
        end
      end
    end
  end
end
