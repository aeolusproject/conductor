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
                    :target_images => [@target_image])
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
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "BuildDeleteFailure"
            resp['error']['message'].should == "Could not find Build 3"
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

    it_behaves_like "Api::BuildsController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::BuildsController responding with XML"
  end

end
