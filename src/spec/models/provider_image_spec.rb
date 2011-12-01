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
