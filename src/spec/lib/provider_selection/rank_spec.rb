#
#   Copyright 2013 Red Hat, Inc.
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

describe ProviderSelection::Rank do

  context '.build_from_assembly_instances' do
    before(:each) do
      pool = FactoryGirl.create(:pool)

      @provider_account_1 = FactoryGirl.create(:mock_provider_account, :label => "test_account_1")
      @provider_account_2 = FactoryGirl.create(:mock_provider_account, :label => "test_account_2")
      @provider_account_3 = FactoryGirl.create(:mock_provider_account, :label => "test_account_3")

      assembly_match_1 = DeployableMatching::AssemblyMatch.new(@provider_account_1, nil, nil, nil, nil, nil)
      assembly_match_2 = DeployableMatching::AssemblyMatch.new(@provider_account_2, nil, nil, nil, nil, nil)
      assembly_instance_1 = DeployableMatching::AssemblyInstance.new(nil, nil, nil, [assembly_match_1, assembly_match_2])

      assembly_match_3 = DeployableMatching::AssemblyMatch.new(@provider_account_1, nil, nil, nil, nil, nil)
      assembly_match_4 = DeployableMatching::AssemblyMatch.new(@provider_account_3, nil, nil, nil, nil, nil)
      assembly_instance_2 = DeployableMatching::AssemblyInstance.new(nil, nil, nil, [assembly_match_3, assembly_match_4])

      assembly_match_5 = DeployableMatching::AssemblyMatch.new(@provider_account_1, nil, nil, nil, nil, nil)
      assembly_match_6 = DeployableMatching::AssemblyMatch.new(@provider_account_2, nil, nil, nil, nil, nil)
      assembly_match_7 = DeployableMatching::AssemblyMatch.new(@provider_account_3, nil, nil, nil, nil, nil)
      assembly_instance_3 = DeployableMatching::AssemblyInstance.new(nil, nil, nil, [assembly_match_5, assembly_match_6, assembly_match_7])

      assembly_instances = [assembly_instance_1, assembly_instance_2, assembly_instance_3]
      @rank = ProviderSelection::Rank.build_from_assembly_instances(pool, assembly_instances)
    end

    it "should create default priority group" do
      @rank.priority_groups.length.should == 1
      @rank.default_priority_group.should == @rank.priority_groups.first
    end

    it "should find common provider account without any redundant element" do
      @rank.default_priority_group.matches.length == 1
      @rank.default_priority_group.matches.first.provider_account.should == @provider_account_1
    end
  end

  context '#ordered_priority_groups' do
    before(:each) do
      pool = FactoryGirl.create(:pool)
      @rank = ProviderSelection::Rank.new(pool)
    end

    it "should return priority groups ordered by score" do
      @rank.priority_groups << ProviderSelection::PriorityGroup.new(100)
      @rank.priority_groups << ProviderSelection::PriorityGroup.new(-100)

      @rank.ordered_priority_groups.length.should == 2
      @rank.ordered_priority_groups[0].score.should > @rank.ordered_priority_groups[1].score
      @rank.ordered_priority_groups[0].score.should == 100
      @rank.ordered_priority_groups[1].score.should == -100
    end
  end

end
