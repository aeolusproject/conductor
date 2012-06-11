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

describe Deployment do
  before(:each) do
    @quota = FactoryGirl.create :quota
    @pool = FactoryGirl.create(:pool, :quota_id => @quota.id)
    @deployment = Factory.build(:deployment, :pool_id => @pool.id)
    @hwp1 = FactoryGirl.create(:front_hwp1)
    @hwp2 = FactoryGirl.create(:front_hwp2)
    @actions = ['start', 'stop']
  end

  describe "validations" do
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
      [nil, '', 'x'*51].each do |invalid_name|
        @deployment.name = invalid_name
        @deployment.should_not be_valid
      end
      @deployment.name = 'x'*50
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
  end

  describe ".get_action_list" do
    it "should tell apart valid and invalid actions" do
      @deployment.stub!(:get_action_list).and_return(@actions)
      @deployment.valid_action?('invalid action').should == false
      @deployment.valid_action?('start').should == true
    end

    it "should return action list" do
      @deployment.get_action_list.should eql(["start", "stop", "reboot"])
    end
  end

  describe ".properties" do
    it "should return properties hash" do
      @deployment.properties.should be_a_kind_of(Hash)
      @deployment.properties.should == {:created=>nil, :pool=>@deployment.pool.name, :owner=>"John  Smith", :name=>@deployment.name}
    end
  end

  describe ".destroy" do
    it "should be removable under with stopped or create_failed instances" do
      @deployment.save!
      inst1 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      inst2 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      @deployment.reload
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

    it "should send stop request to all running instances before it's destroyed" do
      @deployment.save!
      inst1 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      inst2 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      inst2.state = Instance::STATE_STOPPED
      inst2.save!
      inst3 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      @deployment.reload
      Taskomatic.stub!(:stop_instance).and_return(nil)
      @deployment.stop_instances_and_destroy!
      inst1.tasks.last.action.should == 'stop'
      inst3.tasks.last.action.should == 'stop'
    end

    it "should allow for a soft delete" do
      second_deployment = Factory.build(:deployment,
                                        :pool_id => @deployment.pool_id,
                                        :name => "soft delete deployment")
      second_deployment.save!
      second_deployment_id = second_deployment.id

      lambda { Deployment.find(second_deployment_id) }.should_not raise_error(ActiveRecord::RecordNotFound)
      lambda { Deployment.only_deleted.find(second_deployment_id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda{ Deployment.unscoped.find(second_deployment_id) }.should_not raise_error(ActiveRecord::RecordNotFound)

      expect { second_deployment.destroy }.to change(Deployment, :count).by(-1)

      copy_second_deployment = Factory.build(:deployment,
                                        :pool_id => @deployment.pool_id,
                                        :name => "soft delete deployment")
      copy_second_deployment.should be_valid

      lambda { Deployment.find(second_deployment_id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { Deployment.only_deleted.find(second_deployment_id) }.should_not raise_error(ActiveRecord::RecordNotFound)
      lambda{ second_deployment = Deployment.unscoped.find(second_deployment_id) }.should_not raise_error(ActiveRecord::RecordNotFound)

      second_deployment.destroy!

      lambda { Deployment.find(second_deployment_id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { Deployment.only_deleted.find(second_deployment_id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda{ Deployment.unscoped.find(second_deployment_id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".provider" do
    it "should return provider for a deployment where only some instances have set provider account" do
      @deployment.instances << FactoryGirl.create(:mock_running_instance, :provider_account => nil, :deployment => @deployment)
      @deployment.instances << FactoryGirl.create(:mock_running_instance, :deployment => @deployment)
      @deployment.provider.should_not be_nil
    end
  end

  describe ".start_time" do
    it "should return start_time once an instance has started" do
      @deployment.save!
      @deployment.start_time.should be_nil
      instance = Factory.create :mock_pending_instance, :deployment_id => @deployment.id
      instance.save!
      @deployment.start_time.should be_nil
      instance.state = Instance::STATE_RUNNING
      instance.save!
      @deployment.start_time.should_not be_nil
    end
  end

  describe ".end_time" do
    it "should return end_time once an instance has started and stopped" do
      @deployment.save!
      instance = Factory.create :mock_pending_instance, :deployment_id => @deployment.id
      instance.save!
      instance.state = Instance::STATE_RUNNING
      instance.save!
      @deployment.end_time.should be_nil
      instance.state = Instance::STATE_STOPPED
      instance.save!
      @deployment.end_time.should_not be_nil
    end
  end

  describe "logging" do
    it "should log events as instances start and stop" do
      @deployment.save!
      instance1 = Factory.create :mock_pending_instance, :deployment_id => @deployment.id
      instance2 = Factory.create :mock_pending_instance, :deployment_id => @deployment.id
      instance1.save!
      @deployment.events.where(:status_code => 'first_running').should be_empty
      instance1.state = Instance::STATE_RUNNING
      instance1.save!
      @deployment.events.where(:status_code => 'first_running').should be_present
      @deployment.events.where(:status_code => 'all_running').should be_empty
      instance2.state = Instance::STATE_RUNNING
      instance2.save!
      @deployment.events.where(:status_code => 'all_running').should be_present
      # Now test stop events
      instance1.state = Instance::STATE_STOPPED
      instance1.save!
      @deployment.events.where(:status_code => 'some_stopped').should be_present
      @deployment.events.where(:status_code => 'all_stopped').should_not be_present
      instance2.state = Instance::STATE_STOPPED
      instance2.save!
      @deployment.events.where(:status_code => 'all_stopped').should be_present
    end
  end

  describe ".check_assemblies_matches" do
    before do
      admin_perms = FactoryGirl.create :admin_permission
      @user_for_launch = admin_perms.user
      @user_for_launch.quota.maximum_running_instances = 1
      @session = FactoryGirl.create :session
      @session_id = @session.session_id
      SessionEntity.update_session(@session_id, @user_for_launch)
      @deployment.stub(:common_provider_accounts_for).and_return(["test","test"])
    end

    it "return error when user quota was reached" do
      Instance.any_instance.stub(:matches).and_return(["test","test"])
      @deployment.stub!(:find_match_with_common_account).and_return([[], true, []])
      errors = @deployment.check_assemblies_matches(@session_id, @user_for_launch)
      errors.should have(1).items
      errors.last.should include I18n.t('instances.errors.user_quota_reached')
    end
  end

  describe "using image from iwhd" do
    before do
      image_id = @deployment.deployable_xml.assemblies.first.image_id
      @provider_image = provider_name = Aeolus::Image::Warehouse::Image.find(image_id).latest_pushed_build.provider_images.first
      provider_name = @provider_image.provider_name
      provider1 = FactoryGirl.create(:mock_provider, :name => provider_name)
      provider2 = FactoryGirl.create(:mock_provider)
      @provider_account1 = FactoryGirl.create(:mock_provider_account, :label => 'testaccount', :provider => provider1, :priority => 10)
      @provider_account2 = FactoryGirl.create(:mock_provider_account, :label => 'testaccount2', :provider => provider2, :priority => 20)
      @deployment.pool.pool_family.provider_accounts = [@provider_account2, @provider_account1]
      admin_perms = FactoryGirl.create :admin_permission
      @user_for_launch = admin_perms.user
      @session = FactoryGirl.create :session
      @session_id = @session.session_id
      SessionEntity.update_session(@session_id, @user_for_launch)
    end

    it "should return errors when checking assemblies matches which are not launchable" do
      @deployment.check_assemblies_matches(@session_id, @user_for_launch).should be_empty
      @deployment.pool.pool_family.provider_accounts.destroy_all
      @deployment.check_assemblies_matches(@session_id, @user_for_launch).should_not be_empty
    end

    it "should launch instances when launching deployment" do
      @deployment.instances.should be_empty

      Taskomatic.stub!(:create_instance!).and_return(true)
      @deployment.create_and_launch(@session_id, @user_for_launch)
      @deployment.errors.should be_empty
      @deployment.instances.count.should == 2
    end

    it "should match provider accounts according to priority when launching deployment" do
      @deployment.save!
      @deployment.instances.should be_empty

      Instance.any_instance.stub(:provider_images_for_match).and_return([@provider_image])
      Taskomatic.stub!(:create_dcloud_instance).and_return(true)
      Taskomatic.stub!(:handle_dcloud_error).and_return(true)
      Taskomatic.stub!(:handle_instance_state).and_return(true)
      @deployment.create_and_launch(@session_id, @user_for_launch)
      @deployment.errors.should be_empty
      @deployment.reload
      @deployment.instances.count.should == 2
      @deployment.instances[0].provider_account.should == @provider_account1
      @deployment.instances[1].provider_account.should == @provider_account1
      @provider_account1.priority = 30
      @provider_account1.save!
      deployment2 = Factory.create(:deployment, :pool_id => @pool.id)
      deployment2.create_and_launch(@session_id, @user_for_launch)
      deployment2.errors.should be_empty
      deployment2.reload
      deployment2.instances.count.should == 2
      deployment2.instances[0].provider_account.should == @provider_account2
      deployment2.instances[1].provider_account.should == @provider_account2
    end

    it "should not fail to launch if a provider account has a nil priority" do
      @deployment.save!
      @deployment.instances.should be_empty

      @provider_account1.priority = nil
      @provider_account1.save!

      Instance.any_instance.stub(:provider_images_for_match).and_return([@provider_image])
      Taskomatic.stub!(:create_dcloud_instance).and_return(true)
      Taskomatic.stub!(:handle_dcloud_error).and_return(true)
      Taskomatic.stub!(:handle_instance_state).and_return(true)
      @deployment.create_and_launch(@session_id, @user_for_launch)
      @deployment.errors.should be_empty
      @deployment.reload
      @deployment.instances.count.should == 2
      @deployment.instances[0].provider_account.should == @provider_account2
      @deployment.instances[1].provider_account.should == @provider_account2
    end

    it "should not create deployment with instances if match not found" do
      @deployment.instances.should be_empty
      @deployment.pool.pool_family.provider_accounts.destroy_all
      Taskomatic.stub!(:create_instance!).and_return(true)
      @deployment.create_and_launch(@session_id, @user_for_launch)
      @deployment.errors.should_not be_empty
      lambda { Deployment.find(@deployment.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end

    context "partial_launch is enabled" do
      before :each do
        @deployment.update_attribute(:partial_launch, true)
      end

      it "should set create_failed status for instances if instance's launch raises an exception" do
        @deployment.instances.should be_empty
        Taskomatic.stub!(:create_dcloud_instance).and_raise("an exception")
        @deployment.create_and_launch(@session_id, @user_for_launch)
        @deployment.reload
        @deployment.instances.should_not be_empty
        @deployment.instances.each {|i| i.state.should == Instance::STATE_CREATE_FAILED}
      end
    end
  end

  describe ".stop_instances_and_destroy!" do
    it "should be able to stop running instances on deletion" do
      @deployment.save!
      inst1 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      inst2 = Factory.create :mock_running_instance, :deployment_id => @deployment.id
      @deployment.reload

      @deployment.stop_instances_and_destroy!
      inst1.reload
      inst2.reload

      # this emulates Condor stopping the actual instances
      # and dbomatic reflecting the changes back to Conductor
      inst1.state = Instance::STATE_STOPPED; inst1.save!
      inst2.state = Instance::STATE_STOPPED; inst2.save!


      # verify that the deployment and all its instances are deleted
      lambda { Deployment.find(@deployment.id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { Instance.find(inst1.id) }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { Instance.find(inst2.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".any_instance_running?" do
    it "should return false if no deployed instances" do
      deployment = Factory.build :deployment
      instance = Factory.build(:mock_running_instance, :deployment => deployment)
      instance2 = Factory.build(:mock_pending_instance, :deployment => deployment)
      deployment.stub(:instances) { [instance, instance2] }
      deployment.any_instance_running?.should be_true
      instance.state = Instance::STATE_PENDING
      deployment.any_instance_running?.should be_false
    end
  end

  describe "state" do
    context "in running state" do
      before :each do
        @deployment.state = Deployment::STATE_RUNNING
        @deployment.save!
        @inst1 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_RUNNING)
        @inst2 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_RUNNING)
        @deployment.instances << @inst1
        @deployment.instances << @inst2
      end

      it "should be incomplete if only some instances are running" do
        @inst1.state = Instance::STATE_ERROR
        @inst1.save!
        @deployment.reload
        @deployment.state.should == Deployment::STATE_INCOMPLETE
      end
    end

    context "in pending state" do
      before :each do
        @deployment.state = Deployment::STATE_PENDING
        @deployment.save!
        @inst1 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_PENDING)
        @inst2 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_PENDING)
        @deployment.instances << @inst1
        @deployment.instances << @inst2
      end

      it "should be pending if only some instances are running" do
        @inst1.state = Instance::STATE_RUNNING
        @inst1.save!
        @deployment.reload
        @deployment.state.should == Deployment::STATE_PENDING
      end

      it "should be running if all instances are running" do
        @inst1.state = Instance::STATE_RUNNING
        @inst1.save!
        @inst2.state = Instance::STATE_RUNNING
        @inst2.save!
        @deployment.reload
        @deployment.state.should == Deployment::STATE_RUNNING
      end

      context "partial_launch disabled" do
        before :each do
          @deployment.update_attribute(:partial_launch, false)
        end

        it "should be rollback_in_progress if an instance fails" do
          Instance.any_instance.stub(:stop).and_return(true)
          @inst2.state = Instance::STATE_ERROR
          @inst2.save!
          @deployment.reload
          @deployment.state.should == Deployment::STATE_ROLLBACK_IN_PROGRESS
        end

        it "should stop all running instances if an instance fails" do
          @inst1.state = Instance::STATE_RUNNING
          @inst1.save!
          Instance.any_instance.stub(:stop).and_return(true)
          Instance.any_instance.should_receive(:stop)
          @inst2.state = Instance::STATE_ERROR
          @inst2.save!
        end
      end

      context "partial_launch enabled" do
        before :each do
          @deployment.update_attribute(:partial_launch, true)
        end

        it "should not change deployment's state if an instance fails" do
          @inst2.state = Instance::STATE_ERROR
          @inst2.save!
          @deployment.reload
          @deployment.state.should == Deployment::STATE_PENDING
        end
      end
    end

    context "in rollback_in_progress" do
      before :each do
        @deployment.state = Deployment::STATE_ROLLBACK_IN_PROGRESS
        @deployment.save!
        @inst1 = Factory.create(:instance,
                                :deployment => @deployment,
                                :state => Instance::STATE_ERROR)
        @inst2 = Factory.create(:instance,
                                :deployment => @deployment,
                                :state => Instance::STATE_PENDING)
        @deployment.instances << @inst1
        @deployment.instances << @inst2
      end

      it "should relaunch the deployment if rollback is finished" do
        Deployment.any_instance.should_receive(:launch!)
        @inst2.update_attribute(:state, Instance::STATE_STOPPED)
      end

      describe "on relaunch" do
        before :each do
          account = Factory.create(:mock_provider_account)
          match1 = FactoryGirl.build(:instance_match,
                                     :provider_account => account,
                                     :instance_id => @inst1.id)
          match2 = FactoryGirl.build(:instance_match,
                                     :provider_account => account,
                                     :instance_id => @inst2.id)
          Instance.any_instance.stub(:launch!).and_return(true)
          Deployment.any_instance.stub(:find_match_with_common_account).
            and_return([[match1, match2], account, []])
          @inst2.update_attribute(:state, Instance::STATE_STOPPED)
        end

        it "should set pending state for the deployment" do
          @deployment.reload
          @deployment.state.should == Deployment::STATE_PENDING
        end

        it "should save instance match for each instance" do
          @inst1.instance_matches.count.should > 0
          @inst2.instance_matches.count.should > 0
        end
      end
    end

    context "in incomplete state" do
      before :each do
        @deployment.state = Deployment::STATE_INCOMPLETE
        @deployment.save!
        @inst1 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_RUNNING)
        @inst2 = Factory.create(:instance, :deployment => @deployment, :state => Instance::STATE_PENDING)
        @deployment.instances << @inst1
        @deployment.instances << @inst2
      end

      it "should be incomplete if no instances are running" do
        @inst1.state = Instance::STATE_ERROR
        @inst1.save!
        @inst2.state = Instance::STATE_ERROR
        @inst2.save!
        @deployment.reload
        @deployment.state.should == Deployment::STATE_INCOMPLETE
      end

      it "should be running if all instances are running" do
        @inst2.state = Instance::STATE_RUNNING
        @inst2.save!
        @deployment.reload
        @deployment.state.should == Deployment::STATE_RUNNING
      end
    end

  end

  describe ".instances.instance_parameters" do
    it "should not have any instance parameters" do
      @deployment = Factory.build :deployment
      instance = Factory.build(:mock_running_instance, :deployment => @deployment)
      @deployment.stub(:instances) { [instance] }
      @deployment.instances[0].instance_parameters.should be_empty
    end

    it "should have instance parameters" do
      d = Factory.build :deployment_with_launch_parameters
      instance = Factory.build(:mock_running_instance, :deployment => d)
      d.stub(:instances) { [instance] }
      d.instances[0].instance_parameters.count.should >= 0
    end
  end

  describe ".uptime_1st_instance" do
    context "without events" do
      it "return nil if no events exists" do
        @deployment.uptime_1st_instance.should == nil
      end
    end

    context "with events" do
      let!(:deployment) { Factory :deployment_with_1st_running_all_stopped }

      it "return seconds when some instance is deployed" do
        Time.stub_chain(:now, :utc).and_return(Time.utc(2012, 1, 22, 21, 26))
        deployment.stub_chain(:instances, :deployed).and_return(["bla"])
        deployment.uptime_1st_instance.should == 201147.0
      end


      it "return seconds when all instances are stopped" do
        deployment.uptime_1st_instance.should == 86400.0
      end

      it "return nil when either any instance of deployments never start" do
        deployment.events.first.destroy
        deployment.uptime_1st_instance.should == nil
      end

      it "return nil when instances are running but event with status code 'first_running' doesn't exist'" do
        deployment.stub_chain(:instances, :deployed).and_return(["test"])
        deployment.events.first.destroy
        deployment.uptime_1st_instance.should == nil
      end
    end
  end

  describe ".uptime_all" do
    context "without events" do
      it "return nil if no events exists" do
        @deployment.uptime_all.should == nil
      end
    end

    context "with events" do
      let!(:deployment) { Factory :deployment_with_all_running_stopped_some_stopped }

      it "return seconds when all instances of deployment are running" do
        Time.stub_chain(:now, :utc).and_return(Time.utc(2012, 1, 22, 21, 26))
        deployment.stub_chain(:instances, :count).and_return(2)
        deployment.stub_chain(:instances, :deployed, :count).and_return(2)
        deployment.uptime_all.should == 201147.0
      end

      it "return seconds when some instance of deployment is stopped" do
        deployment.stub_chain(:instances, :count).and_return(3)
        deployment.stub_chain(:instances, :deployed, :count).and_return(2)
        deployment.uptime_all.should == 7200.0

      end

      it "return seconds when all instances of deployment are stopped" do
        deployment.stub_chain(:instances, :count).and_return(1)
        deployment.stub_chain(:instances, :deployed, :count).and_return(0)
        deployment.uptime_all.should == 86400.0
      end

      it "return nil in the other cases" do
        deployment.stub_chain(:instances, :count).and_return(1)
        deployment.stub_chain(:instances, :deployed, :count).and_return(0)
        deployment.events.last.destroy
        deployment.uptime_all.should == nil
      end
    end
  end

  it "should find a single provider account to launch" do
    account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
    account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
    account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")
    @deployment.pool.pool_family.provider_accounts += [account1, account2, account3]
    possible1 = FactoryGirl.build(:instance_match, :provider_account => account1)
    possible2 = FactoryGirl.build(:instance_match, :provider_account => account2)
    possible3 = FactoryGirl.build(:instance_match, :provider_account => account2)
    possible4 = FactoryGirl.build(:instance_match, :provider_account => account3)
    possible5 = FactoryGirl.build(:instance_match, :provider_account => account2)

    # not gonna test the individual instance "machtes" logic again
    # just stub out the behavior
    @deployment.instances << instance1 = Factory.build(:instance)
    instance1.stub!(:matches).and_return([[possible1, possible2], []])
    @deployment.instances << instance2 = Factory.build(:instance)
    instance2.stub!(:matches).and_return([[possible3, possible4], []])
    @deployment.instances << instance3 = Factory.build(:instance)
    instance3.stub!(:matches).and_return([[possible5], []])

    instances = [instance1, instance2, instance3]
    match, account, errors = @deployment.send(:find_match_with_common_account)
    match.should_not be_nil
    account.should eql(account2)
  end
end
