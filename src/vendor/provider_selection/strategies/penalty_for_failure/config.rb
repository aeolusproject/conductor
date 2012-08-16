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

      class Config

        include ActiveModel::Validations
        include ActiveModel::Conversion
        extend ActiveModel::Naming

        attr_accessor :penalty_percentage
        attr_accessor :time_period_minutes
        attr_accessor :failure_count_hard_limit

        validates_presence_of :penalty_percentage
        validates_presence_of :time_period_minutes
        validates_numericality_of :penalty_percentage,
                                  :greater_than => 0, :less_than => 100
        validates_numericality_of :time_period_minutes,
                                  :greater_than => 0, :less_than => 2147483647
        validates_numericality_of :failure_count_hard_limit,
                                  :greater_than => 0, :less_than => 1000,
                                  :allow_blank => true

        def initialize(attributes = {})
          attributes ||= ProviderSelection::Strategies::PenaltyForFailure::Strategy.default_options

          attributes.each do |name, value|
            send("#{name}=", value)
          end
        end

        def persisted?
          false
        end

        def to_hash
          {
            :penalty_percentage => @penalty_percentage.to_i,
            :time_period_minutes => @time_period_minutes.to_i,
            :failure_count_hard_limit => @failure_count_hard_limit.to_i
          }
        end

      end

    end
  end
end
