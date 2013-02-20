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
    module CostOrder

      class Strategy
        include ProviderSelection::ChainableStrategy::InstanceMethods

        @default_options = {
          :impact => 1,
        }

        def self.default_options
          @default_options
        end

        #price = hardware_profile.cost_per_hour(instance_hwp)
        def reward_for_price(price)
          return 0 if price.nil?
          mode = @options.key?(:impact) ? @options[:impact] : 1
          base = 33.0 # may become a config option in the future

          penalty = case mode
          when 1
            price*base/2
          when 2
            Math.log((price+1)*base)*10
          when 3
            ((price+2)**2-1) * (base/8)
          else
            0
          end
          penalty =  100 if penalty>100
          penalty = -100 if penalty<-100

          100-penalty
        end

        def calculate
          rank = @strategies.calculate
          rank.default_priority_group.matches.each do |deployable_match|
            old_score = deployable_match.calculated_score

            # calculate average price of hardware_profile in the match
            sum = 0
            have_costs = true
            deployable_match.multi_assembly_match.each_with_index do |assembly_match, index|
              cost = assembly_match.provider_hwp.cost_per_hour(assembly_match.instance_hwp)
              if cost.nil?
                have_costs = false
              else
                sum += cost
              end
              Rails.logger.debug("match hwp #{index}: #{assembly_match.provider_hwp.id}, cost: #{cost}")
            end

            if have_costs
              price = sum / deployable_match.multi_assembly_match.length
              deployable_match.reward_by(reward = reward_for_price(price))
              Rails.logger.debug("avg cost: #{price}, orig score: #{old_score}, reward for cost: #{reward}, new score: #{deployable_match.score}")
            else
              Rails.logger.debug("sorry, a cost was missing, could not calculate the score")
            end
          end

          rank
        end
      end
    end
  end
end
