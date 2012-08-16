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

require File.join(File.dirname(__FILE__), 'strategy')
require File.join(File.dirname(__FILE__), 'config')

module ProviderSelection
  module Strategies
    module PenaltyForFailure

      class Base

        extend ProviderSelection::ChainableStrategyOptions::ClassMethods

        @properties = {
            :edit_partial => 'penalty_for_failure/edit',
            :config_klass => Config
        }

      end

    end
  end
end
