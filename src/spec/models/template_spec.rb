require 'spec_helper'

describe Template do
  it "should have automatically generated uuid after validation" do
    t = Factory.build(:template)
    t.uuid = nil
    t.save
    t.uuid.should_not be_nil
  end

  it "should return list of providers who provides images built from this template" do
    rimg = Factory.build(:mock_replicated_image)
    rimg.save!
    rimg.image.template.providers.size.should eql(1)
  end

  it "should not be valid if template name is too long" do
    t = Factory.build(:template)
    t.name = ('a' * 256)
    t.valid?.should be_false
    t.errors[:name].should_not be_nil
    t.errors[:name].should =~ /^is too long.*/
  end

  it "should not destroy template if there are instances created from this template" do
    inst = Factory.build(:instance)
    inst.save!
    lambda do
      inst.template.destroy
    end.should_not change(Template, :count)
  end

  it "should update xml when template is saved" do
    tpl = Factory.build(:template)
    tpl.packages = ['test']
    tpl.save!
    tpl2 = Template.find(tpl)
    tpl2.packages.should == ['test']
  end
end
