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

describe ProviderImage do
  before do
    @provider = Factory.build(:mock_provider)
    @provider.name = "mock"
    @provider.save
  end

  describe "all" do
    it "should contain testing object" do
       ProviderImage.all.select {|i| i.uuid == "3cdd9f26-b211-454b-89ff-655b0ebbff03"}.size.should == 1
    end
  end

  describe "find" do
    it "should contain testing object" do
      ProviderImage.find('3cdd9f26-b211-454b-89ff-655b0ebbff03').uuid.should == "3cdd9f26-b211-454b-89ff-655b0ebbff03"
    end

    it "should return nil" do
      ProviderImage.find('give_me_nil').should == nil
    end
  end

  describe "target image" do
    it "should return target image" do
      ProviderImage.find("3cdd9f26-b211-454b-89ff-655b0ebbff03").target_image.should ==
        TargetImage.find("1a955a06-ca92-4546-9121-6c35e162f67b")
    end
  end

  describe "provider" do
    it "should return provider" do
      ProviderImage.find("3cdd9f26-b211-454b-89ff-655b0ebbff03").provider.should ==
        @provider
    end
  end

end
