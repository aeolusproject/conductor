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

describe TargetImage do
  describe "all" do
    it "should contain testing object" do
       TargetImage.all.select {|i| i.uuid == "1a955a06-ca92-4546-9121-6c35e162f67b"}.size.should == 1
    end
  end

  describe "find" do
    it "should contain testing object" do
      TargetImage.find('1a955a06-ca92-4546-9121-6c35e162f67b').uuid.should == "1a955a06-ca92-4546-9121-6c35e162f67b"
    end

    it "should return nil" do
      TargetImage.find('give_me_nil').should == nil
    end
  end

  describe "image build" do
    it "should return image build" do
      TargetImage.find("1a955a06-ca92-4546-9121-6c35e162f67b").build.should ==
        ImageBuild.find("63838705-8608-44c6-aded-7c243137172c")
    end
  end

  describe "provider images" do
    it "should return provider images" do
      TargetImage.find("1a955a06-ca92-4546-9121-6c35e162f67b").provider_images.should include \
      ProviderImage.find("3cdd9f26-b211-454b-89ff-655b0ebbff03")
    end
  end
end
