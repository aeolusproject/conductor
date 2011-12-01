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

describe Role do

  it "should not be valid if name is too long" do
    u = FactoryGirl.create(:role)
    u.name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:name].should_not be_nil
    u.errors[:name][0].should =~ /^is too long.*/
  end
end
