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
    @deployment.should be_valid

    @deployment.pool_id = nil
    @deployment.should_not be_valid
  end

  it "should require a pool that is not disabled" do
    @deployment.should be_valid

    @deployment.pool.enabled = false
    @deployment.should_not be_valid
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

  it "should return properties hash" do
    @deployment.properties.should be_a_kind_of(Hash)
    @deployment.properties.should == {:created=>nil, :pool=>@deployment.pool.name, :owner=>"John  Smith", :name=>@deployment.name}
  end

  it "should be removable under with stopped or create_failed instances" do
    @deployment.save!
    inst1 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
    inst2 = Factory.create :mock_running_instance, :deployment_id => @deployment.id

    @deployment.should_not be_destroyable
    @deployment.destroy.should == false

    inst1.state = Instance::STATE_CREATE_FAILED
    inst1.save!
    inst2.state = Instance::STATE_STOPPED
    inst2.save!

    @deployment = Deployment.find(@deployment.id)
    @deployment.should be_destroyable
    expect { @deployment.destroy }.to change(Deployment, :count).by(-1)
  end
end
