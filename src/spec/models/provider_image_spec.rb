require 'spec_helper'

describe ProviderImage do
  before do
    create_test_iwhd_data_for("provider_images")
  end

  describe "all" do
    it "should containt testing object" do
      ProviderImage.all.collect {|i| i.uuid == "provider_images_testing_uuid"}.should be_true
    end
  end

  describe "find" do
    it "should containt testing object" do
      ProviderImage.find('provider_images_testing_uuid').uuid.should == "provider_images_testing_uuid"
    end

    it "should return nil" do
      ProviderImage.find('give_me_nil').should == nil
    end
  end
end