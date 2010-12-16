require 'spec_helper'

describe Instance do
  before(:each) do
    @quota = Factory :quota
    @pool = Factory(:pool, :quota_id => @quota.id)
    @instance = Factory.build(:instance, :pool_id => @pool.id)
    @actions = ['start', 'stop']
  end

  it "should require pool to be set" do
    @instance.pool_id = nil
    @instance.should_not be_valid

    @instance.pool_id = 1
    @instance.should be_valid
  end

  it "should require hardware profile to be set" do
    @instance.hardware_profile_id = nil
    @instance.should_not be_valid

    @instance.hardware_profile_id = 1
    @instance.should be_valid
  end

  it "should require template to be set" do
    @instance.template_id = nil
    @instance.should_not be_valid

    @instance.template_id = 1
    @instance.should be_valid
  end

  it "should have a name of reasonable length" do
    [nil, '', 'x'*1025].each do |invalid_name|
      @instance.name = invalid_name
      @instance.should_not be_valid
    end
    @instance.name = 'x'*1024
    @instance.should be_valid

  end

  it "should have unique name" do
    @instance.save!
    second_instance = Factory.build(:instance,
                                    :pool_id => @instance.pool_id,
                                    :name => @instance.name)
    second_instance.should_not be_valid

    second_instance.name = 'unique name'
    second_instance.should be_valid
  end

  it "should be invalid for unknown states" do
    ["new", "pending", "running", "shutting_down", "stopped",
      "create_failed"].each do |valid_state|
      @instance.state = 'invalid_state'
      @instance.should_not be_valid
      @instance.state = valid_state
      @instance.should be_valid
    end
  end


  it "should tell apart valid and invalid actions" do
    @instance.stub!(:get_action_list).and_return(@actions)
    @instance.valid_action?('invalid action').should == false
    @instance.valid_action?('start').should == true
  end

  it "should return action list" do
    @instance.get_action_list.should eql(["reboot", "stop"])
  end

  it "should be able to queue new actions" do
    @instance.stub!(:get_action_list).and_return(@actions)
    user = User.new

    invalid_task = @instance.queue_action(user, 'unknown action')
    invalid_task.should == false
    valid_task = @instance.queue_action(user, 'stop')
    valid_task.should_not == false
  end

  describe "with time capsule" do

    before(:each) do
      Timecop.travel(Time.local(2008, 9, 1, 10, 5, 0, 0, 0))
    end

    after(:each) do
      Timecop.return
    end

    it "should properly calculate the total time that the instance has been in a monitored state" do
      instance = Factory :new_instance

      [ Instance::STATE_PENDING, Instance::STATE_RUNNING, Instance::STATE_SHUTTING_DOWN, Instance::STATE_STOPPED ].each do |s|

        Timecop.freeze(Time.now)

        # Test when instance is still in the same state
        instance.state = s
        instance.save

        Timecop.freeze(Time.now + 2.second)

        instance.total_state_time(s).should >= 2
        instance.total_state_time(s).should <= 3

        # Test when instance has changed state
        Timecop.freeze(Time.now + 1.second)

        instance.state = Instance::STATE_NEW
        instance.save

        Timecop.freeze(Time.now + 1.second)

        instance.total_state_time(s).should >= 3
        instance.total_state_time(s).should <= 4
      end
    end

  end

  it "should return empty list of instance actions when connect to provider fails" do
    provider = Factory.build(:mock_provider2)
    cloud_account = Factory.build(:cloud_account, :provider => provider,
                                                  :username => 'john doe',
                                                  :password => 'asdf')
    cloud_account.stub!(:connect).and_return(nil)
    cloud_account.stub!(:valid_credentials?).and_return(true)
    instance = Factory.create(:instance, :cloud_account => cloud_account)
    instance.get_action_list.should be_empty
  end

end
