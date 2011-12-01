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

describe Deployable do
  it "should generate xml when set from image" do
    image = mock(Aeolus::Image::Warehouse::Image, :id => '3c58e0d6-d11a-4e68-8b12-233783e56d35', :name => 'image1', :uuid => '3c58e0d6-d11a-4e68-8b12-233783e56d35')
    Aeolus::Image::Warehouse::Image.stub(:find).and_return(image)
    hw_profile = FactoryGirl.build(:front_hwp1)
    deployable = FactoryGirl.build(:deployable)
    deployable.set_from_image(image, hw_profile)
    deployable.xml_filename.should eql(image.name)
    deployable.name.should eql(image.name)
    doc = Nokogiri::XML deployable.xml
    doc.at_xpath('/deployable')[:name].should eql(image.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:hwp].should eql(hw_profile.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:name].should eql(image.name)
    doc.at_xpath('/deployable/assemblies/assembly/image')[:id].should eql(image.uuid)
  end
end
