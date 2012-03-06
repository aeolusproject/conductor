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
    deployable.set_from_image(image, deployable.name, hw_profile)
    deployable.xml_filename.should eql(deployable.name)
    doc = Nokogiri::XML deployable.xml
    doc.at_xpath('/deployable')[:name].should eql(deployable.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:hwp].should eql(hw_profile.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:name].should eql(image.name)
    doc.at_xpath('/deployable/assemblies/assembly/image')[:id].should eql(image.uuid)
  end

  it "should not be valid if xml is not parsable" do
    deployable = FactoryGirl.build(:deployable)
    deployable.should be_valid
    deployable.xml = deployable.xml.clone << "</deployable>"
    deployable.should_not be_valid
  end

  it "should not be valid if xml has multiple assemblies with the same name" do
    deployable = FactoryGirl.build(:deployable_unique_name_violation)
    deployable.valid_deployable_xml?
    deployable.errors[:xml].should == [I18n.t('catalog_entries.flash.warning.not_valid_duplicate_assembly_names')]
  end

  it "should have a name of reasonable length" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])
    [nil, '', 'x'*1025].each do |invalid_name|
      deployable.name = invalid_name
      deployable.should_not be_valid
    end
    deployable.name = 'x'*1024
    deployable.should be_valid
  end

  it "should have unique name" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create :deployable, :catalogs => [catalog]
    deployable2 = Factory.build(:deployable, :name => deployable.name)
    deployable2.should_not be_valid

    deployable2.name = 'unique name'
    deployable2.should be_valid
  end

  it "should have xml content" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create :deployable, :catalogs => [catalog]
    deployable.xml = ''
    deployable.should_not be_valid
  end
end
