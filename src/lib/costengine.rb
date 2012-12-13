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

require "costengine/billingmodel"
require "costengine/mixins"

module CostEngine
  def self.infect_models
    InstanceMatch.send(:include, CostEngine::Mixins::InstanceMatch)
    InstanceHwp.send(:include, CostEngine::Mixins::InstanceHwp)
    Instance.send(:include, CostEngine::Mixins::Instance)
    Deployment.send(:include, CostEngine::Mixins::Deployment)
    HardwareProfile.send(:include, CostEngine::Mixins::HardwareProfile)
    HardwareProfile.extend(CostEngine::Mixins::HardwareProfileClass)
    HardwareProfileProperty.send(:include, CostEngine::Mixins::HardwareProfileProperty)
  end

  CHARGEABLE_TYPES = {
    :hardware_profile => 1,
    :hw_cpu           => 2,
    :hw_memory        => 3,
    :hw_storage       => 4,
  }
end
