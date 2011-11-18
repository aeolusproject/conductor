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

describe CatalogEntriesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @image = mock(Aeolus::Image::Warehouse::Image, :id => '3c58e0d6-d11a-4e68-8b12-233783e56d35', :name => 'image1', :uuid => '3c58e0d6-d11a-4e68-8b12-233783e56d35')
    Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
  end

  it "should provide ui to create new catalog entry from image" do
    mock_warden(@admin)
    get :new, :create_from_image => @image.id
    response.should be_success
    response.should render_template("new")
  end

  it "should create new catalog entry from image" do
    hw_profile = FactoryGirl.create(:front_hwp1)
    catalog = FactoryGirl.create(:catalog)
    mock_warden(@admin)
    post(:create, :create_from_image => @image.id, :hardware_profile => hw_profile.id, :catalog_entry => {:catalog_id => catalog.id})
    response.should redirect_to(catalog_catalog_entries_url(catalog.id))
  end

end
