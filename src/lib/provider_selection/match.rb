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

  class Match

    UPPER_LIMIT = 100
    LOWER_LIMIT = -100

    attr_reader :score
    attr_accessor :provider_account
    attr_accessor :hardware_profile

    def initialize(attributes)
      attributes.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    def score=(val)
      raise ArgumentError.new("score cannot be higher than #{UPPER_LIMIT}") if val > UPPER_LIMIT
      raise ArgumentError.new("score cannot be lower than #{LOWER_LIMIT}") if val < LOWER_LIMIT

      @score = val
    end

    # nil values should value more then any other value
    def calculated_score
      if @score.nil?
        UPPER_LIMIT + 1
      else
        @score
      end
    end

    def penalize_by(percentage)
      new_score = calculated_score + ((UPPER_LIMIT - LOWER_LIMIT) * percentage / 100)
      @score = [(UPPER_LIMIT + 1), new_score].min
    end

    def reward_by(percentage)
      new_score = calculated_score - ((UPPER_LIMIT - LOWER_LIMIT) * percentage / 100)
      @score = [LOWER_LIMIT, new_score].max
    end

  end

end
