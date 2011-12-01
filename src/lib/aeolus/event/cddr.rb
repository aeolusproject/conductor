#
#   Copyright 2011 Red Hat, Inc.
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
module Aeolus
  module Event
    class Cddr < Base

      attr_accessor :deployment_id, :deployable_id, :owner,
                    :pool, :provider, :provider_type, :provider_account,
                    :start_reason,:start_time, :terminate_reason, :terminate_time

      # A Cddr object represents a Cloud Deployment Detail Record.
      #
      # The CDDR event details the occurrence of a deployment in the
      # cloud.  This event should be used to audit and analyze the
      # utilization of resources in the cloud.
      #
      # It has the following attributes:
      #
      # * <b>Event Id</b>: unique identifier for this type of event (020002)
      # * <b>Deployment Id</b>: UUID from the conductor system identifying this specific deployment
      # * <b>Deployable Id</b>: UUID of the deployable (what this deployment is launched from)
      # * <b>Owner</b>: User name of the person who owns this deployment
      # * <b>Pool</b>: Name of the Conductor Pool where this Deployment was launched
      # * <b>Provider</b>: Provider where this Deployment was launched (example: "ec2-us-east-1").
      # * <b>Provider Type</b>: Type of cloud this provider is ('EC2', 'RHEV-M', etc)
      # * <b>Provider Account</b>: account used on the specified provider, denoted by username on provider
      # * <b>Start Time</b>: Time this Deployment began running
      # * <b>Start Reason</b>: Initially this will be something simple like 'User Initiated', but may eventually contain other values, like 'Scale'
      # * <b>Terminate Time</b>: Time this Deployment was terminated.
      # * <b>Terminate Reason</b>: Initially this will be something simple like 'User Requested', but may eventually contain other values, like 'System Crash' or 'Quota Exceeded'
      #
      def initialize(args={})
        set_defaults do
          self.event_id = '020002'
          self.start_reason = 'User Initiated'
          self.terminate_reason = 'User Requested'
        end
        super
      end
    end
  end
end
