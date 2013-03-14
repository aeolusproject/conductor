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

module ProviderSelection

  class Rank

    attr_accessor :priority_groups
    attr_reader :pool

    def self.build_from_assembly_instances(pool, assembly_instances)
      rank = Rank.new(pool)

      default_priority_group = PriorityGroup.new(100000)
      rank.default_priority_group = default_priority_group

      matches_by_instances = assembly_instances.map(&:matches)
      provider_account_matches = matches_by_instances.map do |matches|
        matches.map(&:provider_account)
      end

      common_provider_accounts = provider_account_matches.first
      if common_provider_accounts.nil? || common_provider_accounts.empty?
        return rank
      end

      provider_account_matches.each do |provider_accounts|
        common_provider_accounts &= provider_accounts
      end

      common_provider_accounts.each do |provider_account|
        deployable_match = DeployableMatch.new(:provider_account => provider_account)
        matches_by_instances.each do |matches|
          deployable_match.multi_assembly_match <<
            matches.find{ |match| match.provider_account == provider_account }
        end

        default_priority_group.matches << deployable_match
      end

      rank
    end

    def initialize(pool)
      @priority_groups = []
      @pool = pool
    end

    def ordered_priority_groups
      @priority_groups.sort do |a, b|
        if a.score.nil? && b.score.nil?
          0
        elsif a.score.nil?
          1
        elsif b.score.nil?
          -1
        else
          a.score <=> b.score
        end
      end
    end

    def default_priority_group
      @default_priority_group
    end

    def default_priority_group=(val)
      @default_priority_group = val
      priority_groups << val
    end

  end

end