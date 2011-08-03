require 'spec_helper'

describe SuggestedDeployable do
  it "should have a name of reasonable length" do
    suggested_deployable = FactoryGirl.create :suggested_deployable
    [nil, '', 'x'*1025].each do |invalid_name|
      suggested_deployable.name = invalid_name
      suggested_deployable.should_not be_valid
    end
    suggested_deployable.name = 'x'*1024
    suggested_deployable.should be_valid
  end

  it "should have unique name" do
    suggested_deployable = FactoryGirl.create :suggested_deployable
    suggested_deployable2 = Factory.build(:suggested_deployable, :name => suggested_deployable.name)
    suggested_deployable2.should_not be_valid

    suggested_deployable2.name = 'unique name'
    suggested_deployable2.should be_valid
  end

  it "should have a url" do
    suggested_deployable = FactoryGirl.create :suggested_deployable
    suggested_deployable.url = ''
    suggested_deployable.should_not be_valid
  end

end
