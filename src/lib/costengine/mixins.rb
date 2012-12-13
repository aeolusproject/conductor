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
  module Mixins
    module HardwareProfileClass
      def chargeables
        [:memory, :cpu, :storage]
      end
    end

    module HardwareProfile
      def cost_now(t=Time.now)
        Cost.for_chargeable_and_period(1, id, t, t)
      end

      # 'close' associated set of cost
      # that is set the time_to to now
      def close_costs(all=true)
        hwp_cost = cost_now(t=Time.now)
        hwp_cost.close unless hwp_cost.nil?

        if all
          ::HardwareProfile::chargeables.each do |what|
            hwp_prop_cost = send(what).cost_now(t)
            hwp_prop_cost.close unless hwp_prop_cost.nil?
          end
        end
      end

      # cost per hour valid at now
      def default_cost_per_hour
          cost_per_hour(nil)
      end

      def cost_per_hour(instance_hwp)
        now   = Time.now
        start = Time.at((now.to_f/3600).round*3600)
        stop  = start+1.hour-1
        cost_in_time(now, start, stop, instance_hwp)
      end

      # # cost per given interval
      # def min_cost_per_interval(start, stop, instance_hwp=nil)
      #   cost_in_time(start, start, stop, instance_hwp)
      # end

      # * if instance_hwp is nil, returns cost for the default values or
      #   properties
      # * if instance_hwp is given, returns cost for the instance_hwp
      def cost_in_time(ref_time, start, stop, instance_hwp=nil)
        cost = Cost.for_chargeable_and_time(1, id, ref_time)
        return nil if cost.nil?

        price = 0.0
        if cost.billing_model == 'per_property'
          ::HardwareProfile::chargeables.each do |what|
            property = send(what)
            hwp_prop_cost = Cost.for_chargeable_and_time(
                            property.chargeable_type, property.id, ref_time)
            next if hwp_prop_cost.nil?

            unit_price      = hwp_prop_cost.calculate(start, stop)
            number_of_units = instance_hwp.nil? ?
                                #property.sort_value(true) : # put back this line, if we want the minimum
                                property.value.to_f :
                                instance_hwp.send(what.intern).to_f
            Rails.logger.debug([what, unit_price*number_of_units.to_f, unit_price.to_f, number_of_units.to_f].inspect)
            price += unit_price * number_of_units
            Rails.logger.debug(price)
          end
        else
          price = cost.calculate(start, stop)
        end
        price
      end
    end

    module HardwareProfileProperty
      def chargeable_type
        CostEngine::CHARGEABLE_TYPES[('hw_'+name).intern]
      end

      # lookup __today's__ cost or this __backend__ profile property
      def unit_price
        Cost.for_chargeable_and_time(chargeable_type, id, Time.now).price rescue nil
      end

      def cost_now(t=Time.now)
        Cost.for_chargeable_and_period(chargeable_type, id, t, t)
      end
    end

    module InstanceMatch
      def price
        instance_hwp.hardware_profile.price
      end
    end

    module InstanceHwp
      # calculate cost estimate for an instance that was previously running or
      # is running now
      def cost
        start = instance[:time_last_running]
        return nil if start.nil?
        stop = instance[:time_last_stopped] || Time.now

        hardware_profile.cost_in_time(start, start, stop, self)
      end
    end

    module Instance
      def cost
        # NONE: due to a bug (fixed) previously instances did not have instance_hwp
        # so we need to rescue from that
        instance_hwp.cost rescue nil
      end
    end

    module Deployment
      def cost
        instances.inject(0) do |sum, instance|
          return nil if instance.cost.nil?
          sum + instance.cost
        end
      end
    end
  end
end
