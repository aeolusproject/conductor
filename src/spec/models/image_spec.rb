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
