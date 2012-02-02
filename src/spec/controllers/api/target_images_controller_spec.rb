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
require 'aeolus_image'

describe Api::TargetImagesController do
  render_views

  shared_examples_for "Api::TargetImagesController responding with XML" do
    before(:each) do
      send_and_accept_xml

      @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                     :id => '42')
      @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                     :id => '42',
                     :target_identifier => "ami-1234567",
                     :provider => "provider")
      @build  = mock(Aeolus::Image::Warehouse::ImageBuild,
                     :id => '543')
      @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                     :id => '100',
                     :object_type => 'target_image',
                     :template => '12',
                     :build => @build,
                     :provider_images => [@pimage])
    end

    context "when authenticated as admin" do

      before(:each) do
        @admin_permission = FactoryGirl.create :admin_permission
        @admin = @admin_permission.user
        mock_warden(@admin)
      end

      describe "#index" do
        context "when there are 3 target images" do
          before(:each) do
            send_and_accept_xml
            @timage_collection = [@timage, @timage, @timage]
            Aeolus::Image::Warehouse::TargetImage.stub(:all).and_return(@timage_collection)
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have 3 target images" do
            resp = Hash.from_xml(response.body)
            resp['target_images']['target_image'].size.should be_equal(@timage_collection.size)
          end
          it "should have target images with correct attributes" do
            resp = Hash.from_xml(response.body)
            @timage_collection.each_with_index do |timage, index|
              resp['target_images']['target_image'][index]['id'].should == timage.id
              resp['target_images']['target_image'][index]['object_type'].should == timage.object_type
              resp['target_images']['target_image'][index]['template'].should == timage.template
              resp['target_images']['target_image'][index]['build']['id'].should == timage.build.id
              pimgs = resp['target_images']['target_image'][index]['provider_images']
              pimgs['provider_image']['id'].should == @pimage.id
            end
          end
        end

        context "when there is only 1 target images" do
          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::TargetImage.stub(:all).and_return([@timage])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a target image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['target_images']['target_image']['id'].should == @timage.id
            resp['target_images']['target_image']['object_type'].should == @timage.object_type
            resp['target_images']['target_image']['template'].should == @timage.template
            resp['target_images']['target_image']['build']['id'].should == @timage.build.id
            pimgs = resp['target_images']['target_image']['provider_images']
            pimgs['provider_image']['id'].should == @pimage.id
          end
        end

        context "when there is no target images" do
          before(:each) do
            Aeolus::Image::Warehouse::TargetImage.stub(:all).and_return([])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have no target image" do
            resp = Hash.from_xml(response.body)
            resp['target_images']['target_image'].should be_nil
          end
        end
      end

      describe "#show" do
        context "when there is wanted target image in warehouse" do
          before(:each) do
            Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(@timage)
            get :show, :id => '100'
          end

          it { response.should be_success}
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a target image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['target_image']['id'].should == @timage.id
            resp['target_image']['object_type'].should == @timage.object_type
            resp['target_image']['template'].should == @timage.template
            resp['target_image']['build']['id'].should == @timage.build.id
            pimgs = resp['target_image']['provider_images']
            pimgs['provider_image']['id'].should == @pimage.id
          end
        end

        context "when there is NOT wanted target image in warehouse" do
          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(nil)
          end

          context "and it has status in factory" do
            before(:each) do
              @timage_status = 'COMPLETED'
              Aeolus::Image::Factory::TargetImage.stub(:status).and_return(@timage_status)
              @timage_id = '100'
              get :show, :id => @timage_id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
            it "should have a target image with correct attributes" do
              resp = Hash.from_xml(response.body)
              resp['target_image']['id'].should == @timage_id;
              resp['target_image']['status'].should == @timage_status;
            end
          end

          context "and it has NOT status in factory" do
            before(:each) do
              Aeolus::Image::Factory::TargetImage.stub(:status).and_return(nil)
              get :show, :id => '100'
            end

            it { response.should be_not_found}
            it { response.headers['Content-Type'].should include("application/xml") }
            it "should have error" do
              resp = Hash.from_xml(response.body)
              resp['error']['code'].should == "TargetImageStatusNotFound"
              resp['error']['message'].should == "Could not find status for TargetImage 100"
            end
          end

        end
      end

      describe "#destroy" do
        before(:each) do
          send_and_accept_xml
        end

        context "when target image exists" do
          before(:each) do
            Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(@timage)
          end

          context "and delete succeeds" do
            before(:each) do
              @timage.stub(:delete!).and_return(true)

              delete :destroy, :id => @timage.id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

          context "and delete fails" do
            before(:each) do
              @timage.stub(:delete!).and_throw(Exception)

              delete :destroy, :id => @timage.id
            end

            it { response.status.should == 500}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

        end

        context "an object that doesn't exist" do
          before(:each) do
            Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(nil)
            get :destroy, :id => '99'
          end

          context "response code" do
            subject { response.code.to_i }
            it { should == 404 }
          end
          context "response's Content-Type header" do
            subject { response.headers['Content-Type'] }
            it { should include "application/xml" }
          end
          context "response's body" do
            subject { Hash.from_xml response.body }
            it "should have error" do
              subject['error']['code'].should == "TargetImageNotFound"
              subject['error']['message'].should == "Could not find TargetImage 99"
            end
          end
        end
      end
    end

    context "when not authenticated" do
      before(:each) do
        mock_warden(nil)
      end

      describe "#index" do

        before(:each) do
          send_and_accept_xml
          get :index
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#show" do

        before(:each) do
          get :show, :id => '5'
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#destroy" do

        before(:each) do
          delete :destroy, :id => '5'
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

    end
  end

  context "XML format responses for Accept: application/xml" do
    before(:each) do
      send_and_accept_xml
    end

    it_behaves_like "Api::TargetImagesController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::TargetImagesController responding with XML"
  end

end
