#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'spec_helper'

describe Instance do
  before(:each) do
    @quota = FactoryGirl.create :quota
    @pool = FactoryGirl.create(:pool, :quota_id => @quota.id)
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
    instance = Factory.create(:instance, :provider_account => cloud_account)
    instance.get_action_list.should be_empty
  end

  it "shouldn't return any matches if pool quota is reached" do
    @quota.maximum_running_instances = 1
    @quota.running_instances = 1
    @quota.save!
    @instance.matches.last.should include('Pool quota reached')
  end

  it "shouldn't return any matches if pool family quota is reached" do
    quota = @pool.pool_family.quota
    quota.maximum_running_instances = 1
    quota.running_instances = 1
    quota.save!
    @instance.matches.last.should include('Pool family quota reached')
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
    @instance.matches.last.should include('There are no provider accounts associated with pool family of selected pool.')
  end

  it "should not return matches if account quota is exceeded" do
    # Other tests expect that @instance is built but not created, but we need it saved:
    @instance.save!
    build = @instance.image_build || @instance.image.latest_build
    provider = FactoryGirl.create(:mock_provider, :name => build.provider_images.first.provider_name)
    account = FactoryGirl.create(:mock_provider_account, :provider => provider, :label => 'testaccount')
    @pool.pool_family.provider_accounts = [account]
    @pool.pool_family.save!
    @instance.provider_account = account
    @instance.save!
    quota = account.quota
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
    @instance.pool.pool_family.provider_accounts.first.quota.reload
    @instance.matches.first.should be_empty
  end

  it "shouldn't match provider accounts where image is not pushed" do
    @pool.pool_family.provider_accounts = [FactoryGirl.create(:mock_provider_account, :label => 'testaccount')]
    @instance.matches.last.should include('testaccount: image is not pushed to this provider account')
  end

  it "shouldn't match provider accounts where matching hardware profile not found" do
    account = FactoryGirl.create(:mock_provider_account, :label => 'testaccount')
    account.provider.hardware_profiles.destroy_all
    @pool.pool_family.provider_accounts << account
    @instance.matches.last.should include('testaccount: hardware profile match not found')
  end

  it "should return a match if all requirements are satisfied" do
    build = @instance.image_build || @instance.image.latest_build
    provider = FactoryGirl.create(:mock_provider, :name => build.provider_images.first.provider_name)
    @pool.pool_family.provider_accounts = [FactoryGirl.create(:mock_provider_account, :label => 'testaccount', :provider => provider)]
    @instance.matches.first.should_not be_empty
  end

  it "should return csv header string for export" do
    reader = CSV::Reader.create(Instance.csv_export([FactoryGirl.create(:instance)]))
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

  it "should not be launchable if its provider is disabled" do
    instance = FactoryGirl.build(:instance_with_disabled_provider)
    instance.should_not be_enabled
    instance.should_not be_valid
  end

  it "should not be launchable if its pool is disabled" do
    instance = FactoryGirl.build(:instance_in_disabled_pool)
    instance.should_not be_enabled
    instance.should_not be_valid
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
    build = @instance.image_build || @instance.image.latest_build
    provider = FactoryGirl.create(:mock_provider, :name => build.provider_images.first.provider_name)
    account = FactoryGirl.create(:mock_provider_account, :label => 'testaccount_config_server', :provider => provider)
    config_server = FactoryGirl.create(:mock_config_server, :provider_account => account)
    @pool.pool_family.provider_accounts = [account]

    @instance.stub!(:requires_config_server?).and_return(true)

    matches, errors = @instance.matches
    matches.should_not be_empty
    matches.first.provider_account.should eql(account)
  end

  it "should not match if the account does not have a config server and the instance has configs" do
    build = @instance.image_build || @instance.image.latest_build
    provider = FactoryGirl.create(:mock_provider, :name => build.provider_images.first.provider_name)
    account = FactoryGirl.create(:mock_provider_account, :label => 'testaccount_no_config_server', :provider => provider)
    @pool.pool_family.provider_accounts = [account]

    @instance.stub!(:requires_config_server?).and_return(true)

    matches, errors = @instance.matches
    matches.should be_empty
    errors.should_not be_empty
    errors.select {|e| e.include?("no config server available") }.should_not be_empty
  end

  it "should match only the intersecting provider accounts for all instances" do
    account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
    possible1 = Instance::Match.new(nil,account1,nil,nil,nil)
    account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
    possible2 = Instance::Match.new(nil,account2,nil,nil,nil)
    account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")
    possible3 = Instance::Match.new(nil,account3,nil,nil,nil)

    # not gonna test the individual instance "machtes" logic again
    # just stub out the behavior
    instance1 = Factory.build(:instance)
    instance1.stub!(:matches).and_return([[possible1, possible2], []])
    instance2 = Factory.build(:instance)
    instance2.stub!(:matches).and_return([[possible2, possible3], []])
    instance3 = Factory.build(:instance)
    instance3.stub!(:matches).and_return([[possible2], []])

    instances = [instance1, instance2, instance3]
    matches, errors = Instance.matches(instances)
    matches.should_not be_empty
    matches.first.provider_account.should eql(account2)
  end
end
