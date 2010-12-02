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
end
