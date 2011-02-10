require 'spec_helper'

describe Deployable do

  it "should have automatically generated uuid after validation" do
    d = Factory.build(:deployable)
    d.uuid = nil
    d.save
    d.uuid.should_not be_nil
  end

  it "should not be valid if deployable name is too long" do
    d = Factory.build(:deployable)
    d.name = ('a' * 256)
    d.valid?.should be_false
    d.errors[:name].should_not be_nil
    d.errors[:name].should =~ /^is too long.*/
  end

  it "should have associated assembly" do
    d = Factory.build(:deployable)
    d.assemblies.size.should eql(1)
  end

end
