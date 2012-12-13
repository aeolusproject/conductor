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

      class Config

        include ActiveModel::Validations
        include ActiveModel::Conversion
        extend ActiveModel::Naming

        attr_accessor :impact

        validates_presence_of :impact
        validates_numericality_of :impact,
                                  :greater_than => 0, :less_than => 4,
                                  :allow_blank => false

        def initialize(attributes = {})
          attributes ||= ProviderSelection::Strategies::CostOrder::Strategy.default_options

          attributes.each do |name, value|
            send("#{name}=", value)
          end
        end

        def persisted?
          false
        end

        def to_hash
          {
            :impact => @impact.to_i,
          }
        end

      end

    end
  end
end
