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

require 'spec_helper'

describe UserGroup do
  before(:each) do
  end

  it "should create a new local group" do
    user_group = Factory.create(:user_group)
    user_group.should be_valid
    user_group.members.size.should == 0
  end

  it "should create a new ldap group" do
    user_group = Factory.create(:ldap_group)
    user_group.should be_valid
  end

  it "should add members to a new local group" do
    user_group = Factory.create(:user_group)
    user = Factory.create(:tuser)
    user_group.members.size.should == 0
    user_group.members << user
    user_group.reload
    user_group.members.size.should == 1
  end

end
