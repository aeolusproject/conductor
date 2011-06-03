require 'spec_helper'

describe LegacyAssembly do

  it "should have automatically generated uuid after validation" do
    a = Factory.build(:legacy_assembly)
    a.uuid = nil
    a.save
    a.uuid.should_not be_nil
  end

  it "should not be valid if legacy_assembly name is too long" do
    a = Factory.build(:legacy_assembly)
    a.name = ('a' * 256)
    a.valid?.should be_false
    a.errors[:name].should_not be_nil
    a.errors[:name].should =~ /^is too long.*/
  end

  it "should have associated legacy_template" do
    a = Factory.build(:legacy_assembly)
    a.legacy_templates.size.should eql(1)
  end

end
