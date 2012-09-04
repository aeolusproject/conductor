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
  module Strategies
    module PenaltyForFailure

      class Strategy

        include ProviderSelection::ChainableStrategy::InstanceMethods

        @default_options = {
          :penalty_percentage => 5,
          :time_period_minutes => 4 * 60
        }

        def self.default_options
          @default_options
        end

        def calculate
          rank = @strategies.calculate

          # Query the number of failures for each provider account
          failures_count = {}
          rank.default_priority_group.matches.map(&:provider_account).uniq.each do |provider_account|
            failures_count[provider_account] =
              provider_account.failure_count(:from => Time.now - @options[:time_period_minutes].minutes)
          end

          # Modify the score of each match in every priority groups
          rank.priority_groups.each do |priority_group|
            priority_group.matches.each do |match|
              match.penalize_by(failures_count[match.provider_account] * @options[:penalty_percentage])
            end
          end

          return rank unless @options.has_key?(:failure_count_hard_limit)

          # Create priority group for failing provider accounts with higher
          # score than the default one
          failing_provider_accounts = failures_count.inject([]) do |result, (provider_account, failure_count)|
            if failure_count >= @options[:failure_count_hard_limit]
              result << provider_account
            end

            result
          end.uniq

          rank.priority_groups.each do |priority_group|
            priority_group.delete_matches(:provider_account, failing_provider_accounts)
          end

          failing_priority_group = ProviderSelection::PriorityGroup.new(rank.default_priority_group.score * 100)
          failing_provider_accounts.each do |provider_account|
            failing_priority_group.matches << Match.new(:provider_account => provider_account)
          end

          rank.priority_groups << failing_priority_group

          rank
        end

      end

    end
  end
end
