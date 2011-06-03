require 'spec_helper'

describe LegacyTemplate do
  it "should have automatically generated uuid after validation" do
    t = Factory.build(:legacy_template)
    t.uuid = nil
    t.save
    t.uuid.should_not be_nil
  end

  it "should return list of providers who provides images built from this legacy_template" do
    rimg = Factory.build(:mock_provider_image)
    rimg.save!
    rimg.legacy_image.legacy_template.providers.size.should eql(1)
  end

  it "should not be valid if legacy_template name is too long" do
    t = Factory.build(:legacy_template)
    t.name = ('a' * 256)
    t.valid?.should be_false
    t.errors[:name].should_not be_nil
    t.errors[:name].should =~ /^is too long.*/
  end

  it "should not destroy legacy_template if there are instances created from this legacy_template" do
    inst = Factory.build(:instance)
    inst.save!
    lambda do
      inst.legacy_template.destroy
    end.should_not change(LegacyTemplate, :count)
  end

  it "should update xml when legacy_template is saved" do
    tpl = Factory.build(:legacy_template)
    tpl.packages = ['test']
    tpl.save!
    tpl2 = LegacyTemplate.find(tpl)
    tpl2.packages.should == ['test']
  end

  it "should have warehouse url" do
    t = Factory.build(:legacy_template)
    t.uuid = "uuid"
    t.warehouse_url.should == YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")['baseurl'] + "/templates/" + t.uuid
  end
end
