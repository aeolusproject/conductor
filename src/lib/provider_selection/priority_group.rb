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

  class PriorityGroup

    attr_accessor :matches
    attr_accessor :score

    def initialize(score, matches=[])
      @score = score
      @matches = matches
    end

    def self.create_from_active_record(obj, allowed_matches)
      possible_provider_accounts = obj.all_provider_accounts

      matches = []
      allowed_matches.each do |match| 
        if possible_provider_accounts.include?(match.provider_account)
          matches << Match.new(:provider_account => match.provider_account,
                               :hardware_profile => match.hardware_profile)
        end
      end

      matches.empty? ? nil : PriorityGroup.new(obj.score, matches)
    end

    def match_exists?
      matches.any?
    end

    def get_random_match
      match_sum_score = @matches.sum do |match|
        (Match::UPPER_LIMIT + 1) - match.calculated_score
      end

      # In order to work with 'nil' scores adding the size of the @matches array
      match_sum_score += @matches.length
      random_value = rand(match_sum_score)

      sum = match_sum_score
      matches.each do |match|
        difference = (Match::UPPER_LIMIT + 1) - match.calculated_score
        sum -= (difference + 1)
        if random_value >= sum
          return match
        end
      end

      nil
    end

    def delete_matches(attribute, values)
      matches.delete_if{ |match| values.include?(match.send(attribute)) }
    end

  end

end
