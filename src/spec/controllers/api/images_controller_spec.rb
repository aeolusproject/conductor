#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'spec_helper'
require 'aeolus_image'

describe Api::ImagesController do
  render_views

  shared_examples_for "Api::ImagesController responding with XML" do

    before(:each) do

      @os = mock(:OS, :name => 'fedora', :version => '15', :arch => 'x86_64')
      @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                    :id => '7')
      @image = mock(Aeolus::Image::Warehouse::Image,
                    :id => '5',
                    :os => @os,
                    :name => 'test',
                    :description => 'test image')
      Aeolus::Image::Warehouse::ImageBuild.stub(:find_all_by_image_uuid).and_return([@build])
    end

    context "when authenticated as admin" do

      before(:each) do
        @admin_permission = FactoryGirl.create :admin_permission
        @admin = @admin_permission.user
        mock_warden(@admin)
      end

      describe "#index" do

        context "when there are 3 images" do

          before(:each) do
            @image_collection = [@image, @image, @image]
            Aeolus::Image::Warehouse::Image.stub(:all).and_return(@image_collection)
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have 3 images" do
            resp = Hash.from_xml(response.body)
            resp['images']['image'].size.should be_equal(@image_collection.size)
          end

          it "should have images with correct attributes" do
            resp = Hash.from_xml(response.body)
            @image_collection.each_with_index do |image, index|
              resp['images']['image'][index]['name'].should == image.name
              resp['images']['image'][index]['id'].should == image.id
              resp['images']['image'][index]['os'].should == image.os.name
              resp['images']['image'][index]['arch'].should == image.os.arch
              resp['images']['image'][index]['os_version'].should == image.os.version
              resp['images']['image'][index]['description'].should == image.description
              resp['images']['image'][index]['builds']['build']['id'].should == @build.id
            end
          end

        end

        context "when there is only 1 image" do

          before(:each) do
            Aeolus::Image::Warehouse::Image.stub(:all).and_return([@image])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['images']['image']['name'].should == @image.name
            resp['images']['image']['id'].should == @image.id
            resp['images']['image']['os'].should == @image.os.name
            resp['images']['image']['arch'].should == @image.os.arch
            resp['images']['image']['os_version'].should == @image.os.version
            resp['images']['image']['description'].should == @image.description
          end

        end

        context "when there is no image" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:all).and_return([])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have no image" do
            resp = Hash.from_xml(response.body)
            resp['images']['image'].should be_nil
          end

        end

      end

      describe "#show" do
        context "when there is wanted image" do

          before(:each) do
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
            get :show, :id => '5'
          end

          it { response.should be_success}
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['image']['name'].should == @image.name
            resp['image']['id'].should == @image.id
            resp['image']['os'].should == @image.os.name
            resp['image']['arch'].should == @image.os.arch
            resp['image']['os_version'].should == @image.os.version
            resp['image']['description'].should == @image.description
            resp['image']['builds']['build']['id'].should == @build.id
          end
        end

        context "exception should be thrown if image is missing" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :show, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "ImageNotFound"
            resp['error']['message'].should == "Could not find Image 3"
          end
        end

        context "when there is NOT wanted image" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :show, :id => '5'
          end

          it { response.should be_not_found}
          it { response.headers['Content-Type'].should include("application/xml") }
        end
      end

      describe "#create" do
        context "exception should be thrown if request is empty" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :create, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "InsufficientParametersSupplied"
            resp['error']['message'].should == "Please specify a type, build or import"
          end
        end
      end

      describe "#destroy" do
        context "exception should be thrown if image is missing" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :destroy, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "ImageDeleteFailure"
            resp['error']['message'].should == "Could not find Image 3"
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
          send_and_accept_xml
          get :show, :id => '5'
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

    it_behaves_like "Api::ImagesController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::ImagesController responding with XML"
  end

end
