require 'spec_helper'

describe Deployment do
  before(:each) do
    @quota = FactoryGirl.create :quota
    @pool = FactoryGirl.create(:pool, :quota_id => @quota.id)
    @deployment = Factory.build(:deployment, :pool_id => @pool.id)
    @hwp1 = FactoryGirl.create(:front_hwp1)
    @hwp2 = FactoryGirl.create(:front_hwp2)
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
    @deployment.launch(FactoryGirl.create(:user))[:errors].should be_empty
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

  it "should return errors when checking assemblies matches which are not launchable" do
    user = FactoryGirl.create(:user)
    image_id = @deployment.deployable_xml.assemblies.first.image_id
    provider_name = Image.find(image_id).latest_build.provider_images.first.provider_name
    provider = FactoryGirl.create(:mock_provider, :name => provider_name)
    @deployment.pool.pool_family.provider_accounts = [FactoryGirl.create(:mock_provider_account, :label => 'testaccount', :provider => provider)]
    @deployment.check_assemblies_matches(user).should be_empty
    @deployment.pool.pool_family.provider_accounts.destroy_all
    @deployment.check_assemblies_matches(user).should_not be_empty
  end

  it "should be able to stop running instances on deletion" do
    @deployment.save!
    inst1 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
    inst2 = Factory.create :mock_running_instance, :deployment_id => @deployment.id

    @deployment.stop_instances_and_destroy!

    # this emulates Condor stopping the actual instances
    # and dbomatic reflecting the changes back to Conductor
    inst1.state = Instance::STATE_STOPPED; inst1.save!
    inst2.state = Instance::STATE_STOPPED; inst2.save!


    # verify that the deployment and all its instances are deleted
    lambda {Deployment.find(@deployment.id)}.should raise_error(ActiveRecord::RecordNotFound)
    lambda {Instance.find(inst1.id)}.should raise_error(ActiveRecord::RecordNotFound)
    lambda {Instance.find(inst2.id)}.should raise_error(ActiveRecord::RecordNotFound)
  end

  it "should be return nil if deployment has no events " do
    deployment = Factory :deployment
    deployment.uptime_1st_instance.should be_nil
    deployment.uptime_all.should be_nil
  end

  it "should return false if no deployed instances" do
    deployment = Factory.build :deployment
    instance = Factory.build(:mock_running_instance, :deployment => deployment)
    instance2 = Factory.build(:mock_pending_instance, :deployment => deployment)
    deployment.stub(:instances){[instance, instance2]}
    deployment.any_instance_running?.should be_true
    instance.state = Instance::STATE_PENDING
    deployment.any_instance_running?.should be_false
  end
end
