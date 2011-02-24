require 'spec_helper'

describe Icicle do
  it "should not be valid if uuid is not set" do
    i = Factory.build(:icicle, :uuid => nil)
    i.valid?.should be_false
    i.uuid = ''
    i.valid?.should be_false
  end

  it "should have a unique uuid" do
    old = Factory(:icicle)
    old.should be_valid
    new = Factory.build(:icicle, :uuid => old.uuid)
    new.should_not be_valid
  end
end
