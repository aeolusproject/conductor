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
