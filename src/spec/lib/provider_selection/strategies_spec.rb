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

describe ProviderSelection::Strategies do

  describe ProviderSelection::Strategies::CostOrder::Strategy do

    context "working with one instance deployments" do
      before(:each) do
        account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
        account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
        account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")

        @hwp1 = FactoryGirl.create(:hardware_profile)
        @hwp2 = FactoryGirl.create(:hardware_profile)
        @hwp3 = FactoryGirl.create(:hardware_profile)

        @assembly_match_1 = DeployableMatching::AssemblyMatch.new(account1, nil, nil, @hwp1, nil, nil)
        @assembly_match_2 = DeployableMatching::AssemblyMatch.new(account2, nil, nil, @hwp2, nil, nil)
        @assembly_match_3 = DeployableMatching::AssemblyMatch.new(account3, nil, nil, @hwp3, nil, nil)

        FactoryGirl.create(:cost, :chargeable_id => @hwp1.id, :price => 1)
        FactoryGirl.create(:cost, :chargeable_id => @hwp2.id, :price => 0.02)
        FactoryGirl.create(:cost, :chargeable_id => @hwp3.id, :price => 0.01)
      end

      it "should give better (lower) score for lower cost" do
        assembly_matches = [@assembly_match_1, @assembly_match_2, @assembly_match_3]
        assembly_instance = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches)
        assembly_instances = [assembly_instance]

        @pool = FactoryGirl.create(:pool)
        strategy = FactoryGirl.create(:provider_selection_strategy,
                                      :name => 'cost_order',
                                      :config => { :impact=>1 },
                                      :pool => @pool)
        @pool.stub_chain(:provider_selection_strategies, :enabled).and_return([strategy])

        provider_selection = ProviderSelection::Base.new(@pool, assembly_instances)
        provider_selection.match_exists?.should be_true

        # if we order the matches by score
        matches = provider_selection.rank.default_priority_group.matches.sort!{ |m1,m2| m1.score <=> m2.score }

        # then the first one should be for the cheaper hardware_profile etc.
        matches[0].multi_assembly_match[0].provider_hwp.default_cost_per_hour.should <  matches[1].multi_assembly_match[0].provider_hwp.default_cost_per_hour
        matches[1].multi_assembly_match[0].provider_hwp.default_cost_per_hour.should < matches[2].multi_assembly_match[0].provider_hwp.default_cost_per_hour
      end

      it "hardware profiles with lower prices should be selected more frequently" do
        assembly_matches = [@assembly_match_1, @assembly_match_3]
        assembly_instance = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches)
        assembly_instances = [assembly_instance]
        @pool = FactoryGirl.create(:pool)

        test = Proc.new do |impact|
          strategy = FactoryGirl.create(:provider_selection_strategy,
                                        :name => 'cost_order',
                                        :config => { :impact => impact },
                                        :pool => @pool)
          @pool.stub_chain(:provider_selection_strategies, :enabled).and_return([strategy])

          provider_selection = ProviderSelection::Base.new(@pool, assembly_instances)

          pac_ids = Hash.new(0)
          1000.times {
            pac_id = provider_selection.next_match.provider_account.label
            pac_ids[pac_id] += 1
          }
          pac_ids['test_account1'].should < pac_ids['test_account3']
        end

        # 3.times { |impact| test.call(impact) } # FIXME: the low impact case
        # fails from time to time this has to be fixed by 1) adjusting the
        # price2penalty function; 2) testing this in "statistically correct" way
        2.upto(3).each { |impact| test.call(impact) }
      end
    end

    context "working with multi instance deployments" do
      it "should choose the cheapest provider" do
        pool = FactoryGirl.create(:pool)

        hwp1 = FactoryGirl.create(:hardware_profile)
        hwp2 = FactoryGirl.create(:hardware_profile)
        hwp3 = FactoryGirl.create(:hardware_profile)
        hwp4 = FactoryGirl.create(:hardware_profile)

        account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
        account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")

        # based on the 1st instance, the 1st provider would be more expensive
        # but the 2nd instance should revert the result
        # so in the end the 1st provider shall have the better score
        FactoryGirl.create(:cost, :chargeable_id => hwp1.id, :price => 0.02) # i1
        FactoryGirl.create(:cost, :chargeable_id => hwp2.id, :price => 0.01) # i2
        FactoryGirl.create(:cost, :chargeable_id => hwp3.id, :price => 0.01) # i1
        FactoryGirl.create(:cost, :chargeable_id => hwp4.id, :price => 0.1)  # i2

        assembly_match_1 = DeployableMatching::AssemblyMatch.new(account1, nil, nil, hwp1, nil, nil)
        assembly_match_2 = DeployableMatching::AssemblyMatch.new(account1, nil, nil, hwp2, nil, nil)
        assembly_match_3 = DeployableMatching::AssemblyMatch.new(account2, nil, nil, hwp3, nil, nil)
        assembly_match_4 = DeployableMatching::AssemblyMatch.new(account2, nil, nil, hwp4, nil, nil)

        assembly_matches_for_instance_1 = [assembly_match_1, assembly_match_3]
        assembly_matches_for_instance_2 = [assembly_match_2, assembly_match_4]
        assembly_instance_1 = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches_for_instance_1)
        assembly_instance_2 = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches_for_instance_2)
        assembly_instances = [assembly_instance_1, assembly_instance_2]

        test = Proc.new do |impact|
          strategy = FactoryGirl.create(:provider_selection_strategy,
                                        :name => 'cost_order',
                                        :config => { :impact => impact },
                                        :pool => pool)
          pool.stub_chain(:provider_selection_strategies, :enabled).and_return([strategy])

          provider_selection = ProviderSelection::Base.new(pool, assembly_instances)

          # if we order the matches by score
          matches = provider_selection.rank.default_priority_group.matches.sort!{ |m1,m2| m1.score <=> m2.score }
          # better score should have the 1st provider
          matches[0].provider_account.label.should == 'test_account1'
        end

        3.times { |impact| test.call(impact) }
      end
    end
  end

  describe ProviderSelection::Strategies::StrictOrder::Strategy do
    before(:each) do
      account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
      account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
      account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")

      assembly_match_1 = DeployableMatching::AssemblyMatch.new(account1, nil, nil, nil, nil, nil)
      assembly_match_2 = DeployableMatching::AssemblyMatch.new(account2, nil, nil, nil, nil, nil)
      assembly_match_3 = DeployableMatching::AssemblyMatch.new(account3, nil, nil, nil, nil, nil)
      assembly_matches = [assembly_match_1, assembly_match_2, assembly_match_3]
      assembly_instance = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches)
      @assembly_instances = [assembly_instance]

      pg1 = FactoryGirl.create(:provider_priority_group, :name => 'pg1', :score => 10)
      pg1.provider_accounts = [account1]
      pg2 = FactoryGirl.create(:provider_priority_group, :name => 'pg2', :score => 20)
      pg2.provider_accounts = [account2]
      pg3 = FactoryGirl.create(:provider_priority_group, :name => 'pg3', :score => 30)
      pg3.provider_accounts = [account3]

      @pool = FactoryGirl.create(:pool)
      @pool.provider_priority_groups = [pg1, pg2, pg3]
    end

    it "should return matches from priority group with lower score" do
      strategy = FactoryGirl.create(:provider_selection_strategy, :name => 'strict_order', :pool => @pool)
      @pool.stub_chain(:provider_selection_strategies, :enabled).and_return([strategy])

      provider_selection = ProviderSelection::Base.new(@pool, @assembly_instances)
      provider_selection.match_exists?.should be_true

      # we should have the same number of priority groups in the match as the
      # number of priority groups in the pool plus one for the default_priority_group
      provider_selection.rank.priority_groups.length.should be_equal(@pool.provider_priority_groups.length + 1)

      # then the first match should be from the provider account in the priority
      # group with lowest score
      match = provider_selection.next_match
      match.provider_account.label.should == 'test_account1'
      match.multi_assembly_match.length.should be_equal(1)
    end
  end

  describe ProviderSelection::Strategies::PenaltyForFailure::Strategy do
    before(:each) do
      @account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
      @account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")
      @account3 = FactoryGirl.create(:mock_provider_account, :label => "test_account3")

      assembly_match_1 = DeployableMatching::AssemblyMatch.new(@account1, nil, nil, nil, nil, nil)
      assembly_match_2 = DeployableMatching::AssemblyMatch.new(@account2, nil, nil, nil, nil, nil)
      assembly_match_3 = DeployableMatching::AssemblyMatch.new(@account3, nil, nil, nil, nil, nil)
      assembly_matches = [assembly_match_1, assembly_match_2, assembly_match_3]
      assembly_instance = DeployableMatching::AssemblyInstance.new(nil, nil, nil, assembly_matches)
      @assembly_instances = [assembly_instance]

      @pool = FactoryGirl.create(:pool)
    end

    it "should return matches with provider account with number of failures lower then the failure_count_hard_limit" do
      @account1.stub!(:failure_count).and_return(3)
      @account2.stub!(:failure_count).and_return(4)

      strategy = FactoryGirl.create(:provider_selection_strategy,
                                    :name => 'penalty_for_failure',
                                    :config => { :penalty_percentage => 5,
                                                 :time_period_minutes => 4*60,
                                                 :failure_count_hard_limit => 2 },
                                    :pool => @pool)
      @pool.stub_chain(:provider_selection_strategies, :enabled).and_return([strategy])

      provider_selection = ProviderSelection::Base.new(@pool, @assembly_instances)
      provider_selection.match_exists?.should be_true

      # given we have reached the failure_count_hard_limit in 2 accounts we
      # should get a match from the 3rd
      match = provider_selection.next_match
      match.multi_assembly_match.length.should be_equal(1)
      match.provider_account.label.should == 'test_account3'
    end
  end

end
