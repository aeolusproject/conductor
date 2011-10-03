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

describe Api::BuildsController do
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
        @os = mock(:OS, :name => 'fedora', :version => '15', :arch => 'x86_64')
        @image = mock(Aeolus::Image::Warehouse::Image,
                      :uuid => '5',
                      :os => @os,
                      :name => 'test',
                      :description => 'test image')

        @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                      :uuid => '10',
                      :image => @image)

        Aeolus::Image::Warehouse::ImageBuild.stub(:all).and_return([@build])
        get :index
      end

      it { response.should be_success }
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['builds']['build']['id'].should == @build.uuid
        resp['builds']['build']['image'].should == @image.uuid
      }
    end

    describe "#show" do
      before do
        @os = mock(:OS, :name => 'fedora', :version => '15', :arch => 'x86_64')
        @image = mock(Aeolus::Image::Warehouse::Image,
                      :uuid => '5',
                      :os => @os,
                      :name => 'test',
                      :description => 'test image')

        @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                      :uuid => '10',
                      :image => @image)

        Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(@build)
        get :show, :id => '10'
      end

      it { response.should be_success}
      it { response.headers['Content-Type'].should include("application/xml") }
      it {
        resp = Hash.from_xml(response.body)
        resp['build']['id'].should == @build.uuid
        resp['build']['image'].should == @image.uuid
      }
    end
  end
end
