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

describe Api::BuildsController do
  render_views

  shared_examples_for "Api::BuildsController responding with XML" do
    before(:each) do
      @os = mock(:OS, :name => 'fedora', :version => '15', :arch => 'x86_64')
      @image = mock(Aeolus::Image::Warehouse::Image,
                    :id => '5',
                    :os => @os,
                    :name => 'test',
                    :description => 'test image')

      @target_image = mock(Aeolus::Image::Warehouse::TargetImage,
                           :id => "1")

      @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                    :id => '10',
                    :image => @image,
                    :target_images => [@target_image],
                    :provider_images => [mock(ProviderImage, :target_identifier => "ami-1234567", :provider => "provider")] * 2)
    end

    context "when authenticated as admin" do

      before(:each) do
        @admin_permission = FactoryGirl.create :admin_permission
        @admin = @admin_permission.user
        mock_warden(@admin)
      end

      describe "#index" do
        context "when there are 3 builds" do

          before(:each) do
            @build_collection = [@build, @build, @build]

            Aeolus::Image::Warehouse::ImageBuild.stub(:all).and_return(@build_collection)
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have 3 builds" do
            resp = Hash.from_xml(response.body)
            resp['builds']['build'].size.should be_equal(@build_collection.size)
          end
          it "should have builds with correct attributes" do
            resp = Hash.from_xml(response.body)
            @build_collection.each_with_index do |build, index|
              resp['builds']['build'][index]['id'].should == build.id
              resp['builds']['build'][index]['image'].should == @image.id
            end
          end
        end
        context "when there is only 1 build" do

          before(:each) do
            Aeolus::Image::Warehouse::ImageBuild.stub(:all).and_return([@build])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a build with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['builds']['build']['id'].should == @build.id
            resp['builds']['build']['image'].should == @image.id
          end
        end

        context "when there is no build" do

          before(:each) do
            Aeolus::Image::Warehouse::ImageBuild.stub(:all).and_return([])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have no build" do
            resp = Hash.from_xml(response.body)
            resp['builds']['build'].should be_nil
          end
        end
      end

      describe "#show" do
        context "when there is wanted build" do

          before(:each) do
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(@build)
            get :show, :id => '10'
          end

          it { response.should be_success}
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a build with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['build']['id'].should == @build.id
            resp['build']['image'].should == @image.id
          end
        end

        context "when there is NOT wanted build" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(nil)
            get :show, :id => '10'
          end

          it { response.should be_not_found}
          it { response.headers['Content-Type'].should include("application/xml") }
        end

        context "exception should be thrown for missing image" do
          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(nil)
            get :show, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it { response.status.should == 404}
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "BuildNotFound"
            resp['error']['message'].should == "Could not find Build 3"
          end
        end
      end

      describe "#destroy" do
        context "exception should be thrown for missing image" do
          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(nil)
            get :destroy, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it { response.status.should == 404}
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "BuildNotFound"
            resp['error']['message'].should == "Could not find Build 3"
          end
        end
      end

      describe "#destroy" do
        before(:each) do
          send_and_accept_xml
        end

        context "when build exists" do
          before(:each) do
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(@build)
          end

          context "and delete succeeds" do
            before(:each) do
              @build.stub(:delete!).and_return(true)

              delete :destroy, :id => @build.id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

          context "and delete fails" do
            before(:each) do
              @build.stub(:delete!).and_throw(Exception)

              delete :destroy, :id => @build.id
            end

            it { response.status.should == 500}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

        end

        context "when build is not found" do
          before(:each) do
            Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(nil)
            delete :destroy, :id => @build.id
          end

          it { response.status.should == 404}
          it { response.headers['Content-Type'].should include("application/xml") }
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
          send_and_accept_xml
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

    it_behaves_like "Api::BuildsController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::BuildsController responding with XML"
  end

end
