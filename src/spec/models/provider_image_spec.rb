require 'spec_helper'

describe ProviderImage do
  it "should have a provider_id" do
    i = Factory.build(:mock_provider_image)
    i.should be_valid
    i.provider = nil
    i.should_not be_valid
  end

  it "should have an image_id" do
    i = Factory.build(:mock_provider_image)
    i.should be_valid
    i.image = nil
    i.should_not be_valid
  end

  it "should have a unique uuid" do
    i = Factory(:mock_provider_image, :uuid => '1')
    i.should be_valid
    i = Factory.build(:mock_provider_image, :uuid => '1')
    i.should_not be_valid
  end
end
