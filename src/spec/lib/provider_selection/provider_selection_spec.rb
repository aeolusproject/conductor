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

describe ProviderSelection::Strategies::CostOrder::Strategy do
  before(:each) do
    @account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
    @account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
    @account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")

    @hwp1 = FactoryGirl.create(:hardware_profile)
    @hwp2 = FactoryGirl.create(:hardware_profile)
    @hwp3 = FactoryGirl.create(:hardware_profile)

    @cost1 = FactoryGirl.create(:cost, :chargeable_id => @hwp1.id, :price => 0.1)
    @cost2 = FactoryGirl.create(:cost, :chargeable_id => @hwp2.id, :price => 0.02)
    @cost3 = FactoryGirl.create(:cost, :chargeable_id => @hwp3.id, :price => 0.01)
  end

  it "should give better (lower) score for lower cost" do
    possible1 = FactoryGirl.build(:instance_match, :provider_account => @account1, :hardware_profile => @hwp1)
    possible2 = FactoryGirl.build(:instance_match, :provider_account => @account2, :hardware_profile => @hwp2)
    possible3 = FactoryGirl.build(:instance_match, :provider_account => @account3, :hardware_profile => @hwp3)

    instance = Factory.build(:instance)
    instance.stub!(:matches).and_return([[possible1, possible2, possible3], []])

    provider_selection = ProviderSelection::Base.new([instance])
    strategy_chain = provider_selection.chain_strategy('cost_order', {:impact=>1})

    # we should have a match
    provider_selection.match_exists?.should_not be_false

    rank = strategy_chain.calculate

    # if we order the matches by score
    #matches = rank.default_priority_group.matches.sort_by!{ |match| match.score }
    matches = rank.default_priority_group.matches.sort!{ |m1,m2| m1.score <=> m2.score }

    # then the first one should be for the cheaper hardware_profile etc.
    matches[0].hardware_profile.default_cost_per_hour.should < matches[1].hardware_profile.default_cost_per_hour
    matches[1].hardware_profile.default_cost_per_hour.should < matches[2].hardware_profile.default_cost_per_hour
  end
end
