require 'spec_helper'

describe MetadataObject do

  before(:each) do
    @default_pool_family_metadata = Factory :default_pool_family_metadata
  end

  it "lookup on nonexistent key should return nil" do
    MetadataObject.lookup("can't find me").should be_nil
  end

  it "should require a valid key" do
    [nil, ""].each do |invalid_value|
      @default_pool_family_metadata.key = invalid_value
      @default_pool_family_metadata.should_not be_valid
    end
  end

  it "default pool family should return valid pool family" do
    MetadataObject.lookup("default_pool_family").should be_a(PoolFamily)
  end

  it "setting string value should work" do
    MetadataObject.set("test_string", "stringval")
    MetadataObject.lookup("test_string").should == "stringval"
  end

  it "setting activerecord object value should work" do
    MetadataObject.set("test_obj", Factory(:pool))
    MetadataObject.lookup("test_obj").should be_a(Pool)
  end

end
