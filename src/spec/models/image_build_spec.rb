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
