require 'spec_helper'

describe ProviderImage do
  before do
    @provider = Factory.build(:mock_provider)
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
    it "should return target image" do
      ProviderImage.find("3cdd9f26-b211-454b-89ff-655b0ebbff03").provider.should ==
        @provider
    end
  end

end
