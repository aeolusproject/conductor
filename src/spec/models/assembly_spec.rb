require 'spec_helper'

describe Assembly do

  it "should have automatically generated uuid after validation" do
    a = Factory.build(:assembly)
    a.uuid = nil
    a.save
    a.uuid.should_not be_nil
  end

  it "should not be valid if assembly name is too long" do
    a = Factory.build(:assembly)
    a.name = ('a' * 256)
    a.valid?.should be_false
    a.errors[:name].should_not be_nil
    a.errors[:name].should =~ /^is too long.*/
  end

  it "should have associated template" do
    a = Factory.build(:assembly)
    a.templates.size.should eql(1)
  end

end
