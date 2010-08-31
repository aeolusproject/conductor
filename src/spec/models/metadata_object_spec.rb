require 'spec_helper'

describe MetadataObject do

  before(:each) do
    @default_zone_metadata = Factory :default_zone_metadata
  end

  it "lookup on nonexistent key should return nil" do
    MetadataObject.lookup("can't find me").should be_nil
  end

  it "should require a valid key" do
    [nil, ""].each do |invalid_value|
      @default_zone_metadata.key = invalid_value
      @default_zone_metadata.should_not be_valid
    end
  end

  it "default zone should return valid zone" do
    MetadataObject.lookup("default_zone").should be_a Zone
  end

  it "setting string value should work" do
    MetadataObject.set("test_string", "stringval")
    MetadataObject.lookup("test_string").should == "stringval"
  end

  it "setting activerecord object value should work" do
    MetadataObject.set("test_obj", Factory(:pool))
    MetadataObject.lookup("test_obj").should be_a Pool
  end

end
