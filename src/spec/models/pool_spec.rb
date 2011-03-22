require 'spec_helper'

describe Pool do
  before(:each) do
  end

  it "should require unique name" do
    pool1 = Factory.create(:pool)
    pool2 = Factory.create(:pool)
    pool1.should be_valid
    pool2.should be_valid

    pool2.name = pool1.name
    pool2.should_not be_valid
  end

  it "should not be valid if name is too long" do
    u = Factory(:pool)
    u.name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:name].should_not be_nil
    u.errors[:name].should =~ /^is too long.*/
  end

end
