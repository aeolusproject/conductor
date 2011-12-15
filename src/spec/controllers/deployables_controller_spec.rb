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

describe DeployablesController do

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
    post(:create, :create_from_image => @image.id, :deployable => {:name => @image.name}, :hardware_profile => hw_profile.id, :catalog_id => catalog.id)
    response.should redirect_to(catalog_deployables_url(catalog.id))
  end

end
