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

require 'spec_helper'

describe Cost do
  before(:each) do
    @cost = Factory.create(:cost)
  end

  describe "calculate" do
    it "should return a number" do
      @cost.calculate(t=Time.now, t=Time.now+1.hour).should be_a_kind_of(Numeric)
    end
  end

  describe "close" do
    it "should end the validity" do
      @cost.close
      @cost.valid_to.should <= Time.now
    end
  end
end
