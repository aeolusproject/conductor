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

describe Image do
  describe "all" do
    it "should contain testing object" do
      Image.all.select {|i| i.uuid == "53d2a281-448b-4872-b1b0-680edaad5922"}.size.should == 1
    end
  end

  describe "find" do
    it "should containt testing object" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").uuid.should == "53d2a281-448b-4872-b1b0-680edaad5922"
    end

    it "should return nil" do
      Image.find('give_me_nil').should == nil
    end
  end

  describe "latest build" do
    it "should return build list" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").image_builds.should include \
        ImageBuild.find("63838705-8608-44c6-aded-7c243137172c")
    end

    it "should return latest build" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").latest_build.should ==
        ImageBuild.find("63838705-8608-44c6-aded-7c243137172c")
    end
  end
end
