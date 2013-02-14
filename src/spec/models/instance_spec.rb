#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

require 'csv'

describe Instance do
  before(:each) do
    @quota = FactoryGirl.create :quota
    @pool = FactoryGirl.create(:pool, :quota_id => @quota.id)
    @instance = Factory.build(:instance_with_provider_image, :pool_id => @pool.id)
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

  it "should allow for a soft delete" do
    second_instance = Factory.build(:instance,
                                    :pool_id => @instance.pool_id,
                                    :name => "soft delete instance",
                                    :state => Instance::STATE_CREATE_FAILED)
    second_instance.save!
    second_instance_id = second_instance.id

    lambda { Instance.find(second_instance_id) }.should_not raise_error(ActiveRecord::RecordNotFound)
    lambda { Instance.only_deleted.find(second_instance_id) }.should raise_error(ActiveRecord::RecordNotFound)
    lambda{ Instance.unscoped.find(second_instance_id) }.should_not raise_error(ActiveRecord::RecordNotFound)

    expect { second_instance.destroy }.to change(Instance, :count).by(-1)

    copy_second_instance = Factory.build(:instance,
                                    :pool_id => @instance.pool_id,
                                    :name => "soft delete instance",
                                    :state => Instance::STATE_CREATE_FAILED)
    copy_second_instance.should be_valid

    lambda { Instance.find(second_instance_id) }.should raise_error(ActiveRecord::RecordNotFound)
    lambda { Instance.only_deleted.find(second_instance_id) }.should_not raise_error(ActiveRecord::RecordNotFound)
    lambda{ second_instance = Instance.unscoped.find(second_instance_id) }.should_not raise_error(ActiveRecord::RecordNotFound)
  end

  it "should not destroy associated instance key when instance not destroyable" do
    @instance.instance_key = FactoryGirl.build(:instance_key, :instance => @instance)
    @instance.stub(:destroyable?).and_return(false)
    @instance.destroy
    @instance.instance_key.should_not be_destroyed
  end

  it "should tell apart valid and invalid actions" do
    @instance.stub!(:get_action_list).and_return(@actions)
    @instance.valid_action?('invalid action').should == false
    @instance.valid_action?('start').should == true
  end

  it "should be able to queue new actions" do
    @instance.stub!(:get_action_list).and_return(@actions)
    user = User.new

    invalid_task = @instance.queue_action(user, 'unknown action')
    invalid_task.should == false
    valid_task = @instance.queue_action(user, 'stop')
    valid_task.should_not == false
  end

  it "should create new event when an action is queued" do
    @instance.save!
    @instance.stub!(:get_action_list).and_return(@actions)
    user = User.new
    @instance.queue_action(user, 'stop')
    @instance.events.should_not be_empty
    @instance.events.last.status_code.should == 'stop_queued'
  end

  it "should create event when an instance vanishes" do
    @instance.save!
    @instance.update_attribute(:state, Instance::STATE_VANISHED)
    @instance.events.last.status_code.should == "vanished"
  end

  describe "with time capsule" do

    it "should properly calculate the total time that the instance has been in a monitored state" do
      instance = FactoryGirl.create :new_instance
      Timecop.travel(Time.local(2008, 9, 1, 10, 5, 0, 0, 0))

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
      Timecop.return
    end

  end

  it "should return empty list of instance actions when connect to provider fails" do
    provider = Factory.build(:mock_provider2)
    cloud_account = Factory.build(:provider_account, :provider => provider)
    cloud_account.stub!(:connect).and_return(nil)
    cloud_account.stub!(:valid_credentials?).and_return(true)
    instance = Factory.build(:instance, :provider_account => cloud_account)
    instance.get_action_list.should be_empty
  end

  it "shouldn't return any matches if pool quota is reached" do
    @quota.maximum_running_instances = 1
    @quota.running_instances = 1
    @quota.save!
    @instance.matches.last.should include(_('Pool quota reached'))
  end

  it "shouldn't return any matches if pool family quota is reached" do
    quota = @pool.pool_family.quota
    quota.maximum_running_instances = 1
    quota.running_instances = 1
    quota.save!
    @instance.matches.last.should include(_('Environment quota reached'))
  end

  it "shouldn't return any matches if user quota is reached" do
    quota = @instance.owner.quota
    quota.maximum_running_instances = 1
    quota.running_instances = 1
    quota.save!
    @instance.matches.last.should include('User quota reached')
  end

  it "shouldn't return any matches if there are no provider accounts associated with pool family" do
    @instance.pool.pool_family.provider_accounts = []
    @instance.matches.last.should include(_('There are no Provider Accounts associated with the selected Pool\'s Environment.'))
  end

  it "should not return matches if account quota is exceeded" do
    # Other tests expect that @instance is built but not created, but we need it saved:
    @instance.save!
    @pool.pool_family.provider_accounts = [@instance.provider_account]
    quota = @instance.provider_account.quota
    quota.running_instances = 0
    quota.maximum_running_instances = 1
    quota.save!

    # With no running instances and a quota of one, we should have a match:
    @instance.matches.first.should_not be_empty

    # But with a running instance, we should not have a match
    quota.running_instances = 1
    quota.save!
    # These next two lines are orthogonal but felt fragile so test them while we're here:
    quota.running_instances.should == 1
    quota.should be_reached
    # I'm not sure why this line is required, but it is:
    @instance.reload
    @instance.matches.first.should be_empty
  end

  it "shouldn't match provider accounts where image is not pushed" do
    inst = Factory.create(:instance_with_provider_image)
    inst.stub(:provider_image_for_account).and_return(nil)
    inst.matches.last.should include(_('%s: Image is not pushed to this Provider Account') % inst.provider_account.name)
  end

  it "shouldn't match provider accounts where matching hardware profile not found" do
    account = FactoryGirl.create(:mock_provider_account, :label => 'testaccount')
    account.provider.hardware_profiles.destroy_all
    @pool.pool_family.provider_accounts |= [account]
    @instance.stub(:provider_images_for_account).and_return([])
    @instance.matches.last.should include(_('%s: Hardware Profile match not found') % 'testaccount')
  end

  it "shouldn't match frontend realms mapped to unavailable providers" do
    @pool.pool_family.provider_accounts = [@instance.provider_account]
    # provider's available flag can be changed when a provider account is
    # created (populate_realms is called from after_create callback)
    @instance.provider_account.provider.update_attribute(:available, false)
    @instance.matches.last.should include(_('%s: Provider is not available') % @instance.provider_account.name)
  end

  it "shouldn't match frontend realms mapped to unavailable realms" do
    @instance.save!
    provider_realm = FactoryGirl.create(:provider_realm, :provider => @instance.provider_account.provider, :available => false)
    @instance.provider_account.provider.provider_realms = [provider_realm]
    realm_target = FactoryGirl.create(:realm_backend_target, :provider_realm_or_provider => provider_realm)
    @instance.frontend_realm = realm_target.frontend_realm
    # TODO: this test is currently failing because conductor skips unavailable
    # realms in provider_account.instance_matches mathod
    @instance.matches.last.should include(_('%s: Frontend Realm %s is not mapped to an applicable Provider or Provider Realm') % [@instance.provider_account.name, @instance.frontend_realm.name])
  end


  it "shouldn't return any matches if instance hwp architecture doesn't match image architecture" do
    @instance.hardware_profile.architecture.value = 'i386'
    @instance.matches.last.should include(_('Assembly hardware profile architecture (%s) doesn\'t match image hardware profile architecture (%s).') % ["\'i386\'", "\'x86_64\'"])
  end

  it "should return a match if all requirements are satisfied" do
    @pool.pool_family.provider_accounts = [@instance.provider_account]
    @instance.matches.first.should_not be_empty
  end

  it "should return csv header string for export" do
    reader = CSV.const_defined?(:Reader) ?
               CSV::Reader.create(Instance.csv_export([FactoryGirl.create(:instance)])) :
               CSV.parse(Instance.csv_export([FactoryGirl.create(:instance)]))
    header = reader.shift
      ['Status_code','Event_time','Summary','Source_type','Description','Source_id'].each do |attribute|
        header[0].split(';').include?(attribute).should be_true
      end
  end

  it "should return csv string for export" do
    instance = FactoryGirl.create(:instance)
    export_string = Instance.csv_export([instance]).gsub(/\s+/, "")

    export_string.include?(instance.id.to_s).should be_true
    export_string.include?("Instance").should be_true
    export_string.include?("created").should be_true
  end

  it "should not be launchable on disabled provider account" do
    instance = FactoryGirl.create(:instance_with_provider_image)
    instance.provider_account.provider.update_attribute(:enabled, false)
    errors = instance.matches.last
    errors.find {|e| e =~ /provider must be enabled/i}.should_not be_nil
  end

  it "should not be launchable if its pool is disabled" do
    instance = FactoryGirl.build(:instance_in_disabled_pool)
    instance.should_not be_valid
    instance.errors[:pool].should_not be_empty
    instance.errors[:pool].first.should == "must be enabled"
  end

  it "should not be launchable if its pool's providers are all disabled" do
    instance = FactoryGirl.build(:instance)
    instance.pool.pool_family.provider_accounts |= [ FactoryGirl.create(:disabled_provider_account) ]
    instance.pool.pool_family.stub(:all_providers_disabled?).and_return(true)
    instance.should_not be_valid
    instance.errors[:pool].should_not be_empty
    instance.errors[:pool].first.should == _('has all associated Providers disabled')
  end

  context "When more instances of deployment are starting" do
    it "should return true if first instance of deployment is running" do
      deployment = Factory :deployment
      instance1 = Factory(:mock_running_instance, :deployment => deployment)
      instance2 = Factory(:mock_pending_instance, :deployment => deployment)
      instance3 = Factory(:mock_pending_instance, :deployment => deployment)
      instance1.first_running?.should be_true
      instance2.update_attribute :state, Instance::STATE_RUNNING
      instance2.first_running?.should be_false
    end

    it "should return true if all instance of deployment is running" do
      deployment = Factory :deployment
      instance1 = Factory(:mock_running_instance, :deployment => deployment)
      instance2 = Factory(:mock_running_instance, :deployment => deployment)
      instance3 = Factory(:mock_pending_instance, :deployment => deployment)
      deployment.all_instances_running?.should be_false
      instance3.update_attribute :state, Instance::STATE_RUNNING
      deployment.all_instances_running?.should be_true
    end
  end
  it "should match if the account has a config server and the instance has configs" do
    config_server = FactoryGirl.create(:mock_config_server, :provider_account => @instance.provider_account)
    @pool.pool_family.provider_accounts = [@instance.provider_account]

    @instance.stub!(:requires_config_server?).and_return(true)

    matches, errors = @instance.matches
    matches.should_not be_empty
    matches.first.provider_account.should eql(@instance.provider_account)
  end

  it "should not match if the account does not have a config server and the instance has configs" do
    @pool.pool_family.provider_accounts = [@instance.provider_account]

    @instance.stub!(:requires_config_server?).and_return(true)

    matches, errors = @instance.matches
    matches.should be_empty
    errors.should_not be_empty
    errors.select {|e| e.include?("no Config Server available") }.should_not be_empty
  end

  describe "launch!" do
    it "should create instance_hwp" do
      Taskomatic.stub!(:create_dcloud_instance).and_return(true)
      Taskomatic.stub!(:handle_instance_state).and_return(true)
      Taskomatic.stub!(:handle_dcloud_error).and_return(true)

      instance_match = FactoryGirl.build(:instance_match)
      user_for_launch = FactoryGirl.create(:admin_permission).user

      @instance.launch!(instance_match, user_for_launch, nil, nil)
      @instance.reload

      @instance.instance_hwp.should_not be_nil
    end
  end

  describe ".stopped_after_creation?" do
    before(:each) do
      @instance = FactoryGirl.create(:instance, :pool_id => @pool.id, :state => 'stopped')
      @deployment = FactoryGirl.create :deployment
      @deployment.instances << @instance
    end

    it "should be true if the deployment is pending and the provider doesn't start an instance automatically" do
      @instance.provider_account.provider.provider_type.
        stub!(:goes_to_stop_after_creation?).and_return(true)
      @deployment.update_attribute(:state, Deployment::STATE_PENDING)
      @instance.tasks << InstanceTask.create!({:user        => nil,
                                 :task_target => @instance,
                                 :action      => InstanceTask::ACTION_CREATE})
      @instance.stopped_after_creation?.should be_true
    end
  end
end
