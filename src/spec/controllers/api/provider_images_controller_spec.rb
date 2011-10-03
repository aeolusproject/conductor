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

describe Api::ProviderImagesController do
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
        @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                       :uuid => '300')
        @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                       :uuid => '17',
                       :icicle => '30',
                       :object_type => 'provider_image',
                       :target_identifier => '80',
                       :target_image => @timage)

        Aeolus::Image::Warehouse::ProviderImage.stub(:all).and_return([@pimage])
        get :index
      end

      it { response.should be_success }
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['provider_images']['provider_image']['id'].should == @pimage.uuid
        resp['provider_images']['provider_image']['icicle'].should == @pimage.icicle
        resp['provider_images']['provider_image']['object_type'].should == @pimage.object_type
        resp['provider_images']['provider_image']['target_identifier'].should == @pimage.target_identifier
        resp['provider_images']['provider_image']['target_image']['id'].should == @pimage.target_image.uuid
      }
    end

    describe "#show" do
      before do
        @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                       :uuid => '300')
        @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                       :uuid => '17',
                       :icicle => '30',
                       :object_type => 'provider_image',
                       :target_identifier => '80',
                       :target_image => @timage)

        Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(@pimage)
        get :show, :id => '5'
      end

      it { response.should be_success}
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['provider_image']['id'].should == @pimage.uuid
        resp['provider_image']['icicle'].should == @pimage.icicle
        resp['provider_image']['object_type'].should == @pimage.object_type
        resp['provider_image']['target_identifier'].should == @pimage.target_identifier
        resp['provider_image']['target_image']['id'].should == @pimage.target_image.uuid
      }
    end
  end
end
