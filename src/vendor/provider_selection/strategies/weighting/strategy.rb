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

module ProviderSelection
  module Strategies
    module Weighting

      class Strategy

        include ProviderSelection::ChainableStrategy::InstanceMethods

        def calculate
          rank = @strategies.calculate

          if rank.pool.pool_provider_account_options.any?
            provider_account_scores = Hash.new(0)
            rank.pool.pool_provider_account_options.each do |pool_provider_account_option|
              provider_account_scores[pool_provider_account_option.provider_account] = pool_provider_account_option.score
            end

            rank.priority_groups.each do |priority_group|
              priority_group.matches.each do |match|
                match.reward_by(provider_account_scores[match.provider_account])
              end
            end
          end

          rank
        end

      end

    end
  end
end
