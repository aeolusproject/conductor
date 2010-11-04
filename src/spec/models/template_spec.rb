require 'spec_helper'

describe Template do
  it "should have automatically generated uuid after validation" do
    t = Factory.build(:template)
    t.uuid = nil
    t.save
    t.uuid.should_not be_nil
  end

  it "should return list of providers who provides images built from this template" do
    tpl = Factory.build(:template)
    img = Factory.build(:image, :template_id => tpl)
    provider = Factory.build(:mock_provider)
    rimg = ReplicatedImage.new(:provider_id => provider, :image_id => img)
    rimg.save
    tpl.providers.size.should eql(1)
  end

  it "should not be valid if template name is too long" do
    t = Factory.build(:template)
    t.xml.name = ('a' * 256)
    t.valid?.should be_false
    t.errors[:name].should_not be_nil
    t.errors[:name].should =~ /^is too long.*/
  end
end
