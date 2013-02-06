#
#   Copyright 2013 Red Hat, Inc.
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

require 'spec_helper'

describe InstanceHwp do
  it "should have a cost if it's hwp has a cost" do
    instance_hwp = FactoryGirl.create(:instance_hwp)
    instance_hwp.cost.should be_nil

    cost1 = FactoryGirl.create(:cost,
      :valid_from => Time.now - 1.day,
      :chargeable_id => instance_hwp.hardware_profile.id,
      :price => 0.1)

    instance_hwp.cost.should_not be_nil
  end
end
