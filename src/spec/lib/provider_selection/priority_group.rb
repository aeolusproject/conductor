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

describe ProviderSelection::PriorityGroup do

  it "should process user defined priority groups" do
    priority_group_ar = FactoryGirl.create(:provider_priority_group)
    provider_account = FactoryGirl.create :mock_provider_account
    priority_group_ar.provider_accounts << provider_account

    match = ProviderSelection::Match.new(:provider_account => provider_account)
    priority_group = ProviderSelection::PriorityGroup.create_from_active_record(priority_group_ar, [match])
    priority_group.should_not be nil
  end

  it "should properly filter provider accounts while processing user defined priority groups" do
    priority_group_ar = FactoryGirl.create(:provider_priority_group)
    provider_account = FactoryGirl.create :mock_provider_account
    provider = provider_account.provider
    priority_group_ar.provider_accounts << provider_account
    3.times do
      other_provider_account = FactoryGirl.build(:mock_provider_account_seq, :provider => provider)
      other_provider_account.stub!(:validate_credentials).and_return(true)
      other_provider_account.save

      priority_group_ar.provider_accounts << other_provider_account
    end

    allowed_match = ProviderSelection::Match.new(:provider_account => provider_account)
    priority_group = ProviderSelection::PriorityGroup.create_from_active_record(priority_group_ar, [allowed_match])
    priority_group.matches.length.should eql(1)
    priority_group.matches.first.provider_account.should eql(provider_account)

  end

  it "should be able to delete existing matches" do
    priority_group = ProviderSelection::PriorityGroup.new(0)
    priority_group.matches <<
      ProviderSelection::Match.new(:provider_account => 'Provider Account 1',
                                   :score => 100)
    priority_group.matches <<
        ProviderSelection::Match.new(:provider_account => 'Provider Account 2',
                                     :score => 100)
    priority_group.matches <<
        ProviderSelection::Match.new(:provider_account => 'Provider Account 3',
                                     :score => 0)

    lambda { priority_group.delete_matches(:score, [100]) }.should change(priority_group.matches, :length).from(3).to(1)
  end

end