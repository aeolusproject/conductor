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

  class DeployableMatch

    UPPER_LIMIT = 100
    LOWER_LIMIT = -100

    attr_reader :provider_account
    attr_reader :multi_assembly_match

    def initialize(attributes)
      @multi_assembly_match = []

      score_val = attributes[:score] || attributes['score']
      self.score = score_val if score_val
      attributes.delete_if {|name, value| name.to_s == 'score' }

      attributes.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    def score
      @score || 0
    end

    def score=(val)
      if val > UPPER_LIMIT
        @score = UPPER_LIMIT
      elsif val < LOWER_LIMIT
        @score = LOWER_LIMIT
      else
        @score = val
      end
    end

    def abs_score
      self.score - LOWER_LIMIT
    end

    def penalize_by(percentage)
      self.score -= ((UPPER_LIMIT - 0) * percentage / 100)
    end

    def reward_by(percentage)
      self.score += ((0 - LOWER_LIMIT) * percentage / 100)
    end

  end

end
