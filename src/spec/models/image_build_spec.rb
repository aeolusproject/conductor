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

describe ImageBuild do

  describe "all" do
    it "should contain testing object" do
       ImageBuild.all.select {|i| i.uuid == "63838705-8608-44c6-aded-7c243137172c"}.size.should == 1
    end
  end

  describe "find" do
    it "should contain testing object" do
      ImageBuild.find('63838705-8608-44c6-aded-7c243137172c').uuid.should == "63838705-8608-44c6-aded-7c243137172c"
    end

    it "should return nil" do
      ImageBuild.find('give_me_nil').should == nil
    end
  end

  describe "image" do
    it "should return image" do
      ImageBuild.find("63838705-8608-44c6-aded-7c243137172c").image.should ==
        Image.find("53d2a281-448b-4872-b1b0-680edaad5922")
    end
  end

  describe "target and provider images" do
    it "should return target images" do
      ImageBuild.find("63838705-8608-44c6-aded-7c243137172c").target_images.should include \
      TargetImage.find("1a955a06-ca92-4546-9121-6c35e162f67b")
    end

    it "should return provider images" do
      ImageBuild.find("63838705-8608-44c6-aded-7c243137172c").provider_images.should include \
      ProviderImage.find("3cdd9f26-b211-454b-89ff-655b0ebbff03")
    end
  end
end
