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
