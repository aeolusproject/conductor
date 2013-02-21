#
#   Copyright 2013 Red Hat, Inc.
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

describe DeployableMatching::ImageFetcher do

  before(:each) do
    pool = FactoryGirl.create(:pool)
    catalog = FactoryGirl.create(:catalog, :pool => pool)
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])
    @assembly = deployable.deployable_xml.assemblies.first

    @base_image = FactoryGirl.create(:base_image_with_template)
    Tim::BaseImage.stub(:find_by_uuid).and_return(@base_image)
  end

  it "should fetch base image" do
    DeployableMatching::ImageFetcher.base_image(@assembly).should == @base_image
  end

  it "should return image arch" do
    DeployableMatching::ImageFetcher.image_arch(@assembly).should == 'x86_64'
  end

  it "should fetch provider image" do
    Tim::ProviderImage.any_instance.stub(:create_factory_provider_image).and_return(true)
    Tim::TargetImage.any_instance.stub(:create_factory_target_image).and_return(true)
    provider_image = FactoryGirl.create(:provider_image)

    provider_account = FactoryGirl.create(:mock_provider_account)

    Tim::ProviderImage.stub_chain(:find_by_provider_account_and_image_version,
                                  :complete,
                                  :first).and_return(provider_image)
    DeployableMatching::ImageFetcher.provider_image(@assembly, provider_account ).should == provider_image
  end

end