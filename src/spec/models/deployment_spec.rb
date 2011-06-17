require 'spec_helper'

describe Deployment do
  before(:each) do
    @quota = Factory :quota
    @pool = Factory(:pool, :quota_id => @quota.id)
    @deployment = Factory.build(:deployment, :pool_id => @pool.id)
    @hwp1 = Factory(:front_hwp1)
    @hwp2 = Factory(:front_hwp2)
    @actions = ['start', 'stop']
  end

  it "should require pool to be set" do
    @deployment.pool_id = nil
    @deployment.should_not be_valid

    @deployment.pool_id = 1
    @deployment.should be_valid
  end

# This is in flux, and currently inapplicable
#  it "should require deployable to be set" do
#    @deployment.legacy_deployable_id = nil
#    @deployment.should_not be_valid
#
#    @deployment.legacy_deployable_id = 1
#    @deployment.should be_valid
#  end

  it "should have a name of reasonable length" do
    [nil, '', 'x'*1025].each do |invalid_name|
      @deployment.name = invalid_name
      @deployment.should_not be_valid
    end
    @deployment.name = 'x'*1024
    @deployment.should be_valid

  end

  it "should have unique name" do
    @deployment.save!
    second_deployment = Factory.build(:deployment,
                                    :pool_id => @deployment.pool_id,
                                    :name => @deployment.name)
    second_deployment.should_not be_valid

    second_deployment.name = 'unique name'
    second_deployment.should be_valid
  end

  it "should tell apart valid and invalid actions" do
    @deployment.stub!(:get_action_list).and_return(@actions)
    @deployment.valid_action?('invalid action').should == false
    @deployment.valid_action?('start').should == true
  end

  it "should return action list" do
    @deployment.get_action_list.should eql(["start", "stop", "reboot"])
  end

  it "should launch instances when launching deployment" do
    @deployment.save!
    @deployment.instances.should be_empty
    @deployment.stub!(:condormatic_instance_create).and_return(true)
    @deployment.launch(Factory(:user))[:errors].should be_empty
    @deployment.instances.count.should == 2
  end

end
