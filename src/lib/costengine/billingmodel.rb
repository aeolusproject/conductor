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

module CostEngine
  #
  # implements billing models and utility methods and classing for dealing with
  # billing models
  #
  class BillingModel
    # finds billing model class for given name
    #   * model_name is in the form of 'wall_clock_hour'
    #
    def self.find(model_name)
      begin
        klass = BillingModel.const_get(model_name.camelcase.intern)
        return nil unless BILLING_MODELS.include?(klass)
        klass
      rescue NameError
        nil
      end
    end

    # finds human readable name for given name
    #   * model_name is in the form of 'wall_clock_hour'
    #
    def self.find_name(model_name)
      (find(model_name)::HUMAN_NAME rescue 'none')
    end

    # returns list of billing models as a hash of
    #   human readable name => underscored name
    # used as view helper
    #
    # FIXME: have to call gettext on these, probably at the view level?
    #
    def self.options_for_select
      BILLING_MODELS.inject(OptionsForSelect.new) do |options,model|
        options.merge!(model::HUMAN_NAME => model.to_s.underscore.split('/').last)
      end
    end

    # helper class representing options for <select> html tag and it's rails helper
    #
    class OptionsForSelect < Hash
      def with_none
        merge('none' => 'none')
      end

      def no_parts
        reject { |_,model_name| model_name == 'per_property' }
      end
    end

    # follows implementation of various billing models:
    #  * pay per day/hour/wallclock hour/[minute?]
    #  * later may need per start/stop/whatever

    # bills per wall clock hour i.e. running from 11:55 to 12:05 is billed as 2
    # units
    #
    class WallClockHour
      def self.calculate(price_per_hour, start_t, end_t)
        start_t = start_t.change(:min => 1)
        end_t   = end_t.change(:min => 59)
        price_per_hour * ((end_t-start_t + 3600) / 3600).to_i
      end
      HUMAN_NAME = 'per wall clock hour'
    end

    # bills per 'normal' hour
    #
    class Hour
      def self.calculate(price_per_hour, start_t, end_t)
        price_per_hour * ((end_t-start_t + 3600) / 3600).to_i
      end
      HUMAN_NAME = 'per hour'
    end

    # represents billing per (hardware_profile) property
    #
    class PerProperty
      def self.calculate(price_per_hour, start_t, end_t)
        0
      end
      HUMAN_NAME = 'per property'
    end

    # list of valid billing model classes
    BILLING_MODELS = [WallClockHour,Hour,PerProperty]
  end
end
