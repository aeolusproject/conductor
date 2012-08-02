#
#   Copyright 2012 Red Hat, Inc.
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

describe ProviderSelection do

  before(:each) do
    @account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
    @account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
    @account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")

    possible1 = FactoryGirl.build(:instance_match, :provider_account => @account1)
    possible2 = FactoryGirl.build(:instance_match, :provider_account => @account2)
    possible3 = FactoryGirl.build(:instance_match, :provider_account => @account2)
    possible4 = FactoryGirl.build(:instance_match, :provider_account => @account3)
    possible5 = FactoryGirl.build(:instance_match, :provider_account => @account2)

    instance1 = Factory.build(:instance)
    instance1.stub!(:matches).and_return([[possible1, possible2], []])
    instance2 = Factory.build(:instance)
    instance2.stub!(:matches).and_return([[possible3, possible4], []])
    instance3 = Factory.build(:instance)
    instance3.stub!(:matches).and_return([[possible5], []])

    instances = [instance1, instance2, instance3]
    @provider_selection = ProviderSelection::Base.new(instances)
  end

  it "should give back valid match" do
    match = @provider_selection.next_match
    match.provider_account.should eql(@account2)
  end

  it "should find common provider account" do
    common_provider_accounts = @provider_selection.send(:find_common_provider_accounts)
    common_provider_accounts.should eql([@account2])
  end

  it "should calculate initial rank" do
    rank = @provider_selection.calculate
    rank.priority_groups.length.should eql(1)

    priority_group = rank.priority_groups.first
    priority_group.matches.length.should eql(1)

    match = priority_group.matches.first
    match.provider_account.should eql(@account2)
  end

end