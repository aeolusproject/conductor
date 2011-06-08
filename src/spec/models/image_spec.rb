require 'spec_helper'

describe Image do
  before do
    create_test_iwhd_data_for('images')
  end

  describe "all" do
    it "should containt testing object" do
      Image.all.collect {|i| i.uuid == "images_testing_uuid"}.should be_true
    end
  end

  describe "find" do
    it "should containt testing object" do
      Image.find('images_testing_uuid').uuid.should == "images_testing_uuid"
    end

    it "should return nil" do
      Image.find('give_me_nil').should == nil
    end
  end
end