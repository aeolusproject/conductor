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
require 'pp'

describe Api::TargetImagesController do
  render_views

  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  context "XML format responses for " do
    before do
      send_and_accept_xml
    end

    describe "#index" do
      before do
        @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                       :id => '42')
        @build  = mock(Aeolus::Image::Warehouse::ImageBuild,
                      :id => '543')
        @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                       :id => '100',
                       :icicle => '321',
                       :object_type => 'target_image',
                       :template => '12',
                       :build => @build,
                       :provider_images => [@pimage])

        Aeolus::Image::Warehouse::TargetImage.stub(:all).and_return([@timage])
        get :index
      end

      it { response.should be_success }
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['target_images']['target_image']['id'].should == @timage.id
        resp['target_images']['target_image']['icicle'].should == @timage.icicle
        resp['target_images']['target_image']['object_type'].should == @timage.object_type
        resp['target_images']['target_image']['template'].should == @timage.template
        resp['target_images']['target_image']['build']['id'].should == @timage.build.id
        pimgs = resp['target_images']['target_image']['provider_images']
          pimgs['provider_image']['id'].should == @pimage.id
      }
    end

    describe "#show" do
      before do
        @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                       :id => '42')
        @build  = mock(Aeolus::Image::Warehouse::ImageBuild,
                      :id => '543')
        @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                       :id => '100',
                       :icicle => '321',
                       :object_type => 'target_image',
                       :template => '12',
                       :build => @build,
                       :provider_images => [@pimage])

        Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(@timage)
        get :show, :id => '100'
      end

      it { response.should be_success}
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['target_image']['id'].should == @timage.id
        resp['target_image']['icicle'].should == @timage.icicle
        resp['target_image']['object_type'].should == @timage.object_type
        resp['target_image']['template'].should == @timage.template
        resp['target_image']['build']['id'].should == @timage.build.id
        pimgs = resp['target_image']['provider_images']
          pimgs['provider_image']['id'].should == @pimage.id
      }
    end
  end
end
