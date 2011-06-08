require 'spec_helper'

describe TargetImage do
  before do
    create_test_iwhd_data_for("target_images")
  end

  describe "all" do
    it "should containt testing object" do
      TargetImage.all.collect {|i| i.uuid == "target_images_testing_uuid"}.should be_true
    end
  end

  describe "find" do
    it "should containt testing object" do
      TargetImage.find('target_images_testing_uuid').uuid.should == "target_images_testing_uuid"
    end

    it "should return nil" do
      TargetImage.find('give_me_nil').should == nil
    end
  end
end