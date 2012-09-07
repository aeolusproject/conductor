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
Given /^a user group "([^"]*)" exists$/ do |name|
  unless UserGroup.find_by_name(name)
    FactoryGirl.create :user_group, :name => name
  end
end

Given /^there is a user group "([^"]*)"$/ do |name|
  unless UserGroup.find_by_name(name)
    FactoryGirl.create :user_group, :name => name
  end
end

Then /^there should be (\d+) user groups?$/ do |number|
  UserGroup.count.should == number.to_i
end

When /^I check "([^"]*)" user group$/ do |user_group_name|
  user_group = UserGroup.find_by_name(user_group_name)
  check("user_group_checkbox_#{user_group.id}")
end

When /^I check the "([^"]*)" member$/ do |username|
  member = User.find_by_username(username)
  check("member_checkbox_#{member.id}")
end

Then /^there should be (\d+) user belonging to "([^"]*)"$/ do |count, name|
  user_group = UserGroup.find_by_name(name)
  user_group.members.count == count
end

Given /^there is a user "([^"]*)" belonging to user group "([^"]*)"$/ do |username, group_name|
  member = User.find_by_username(username)
  user_group = UserGroup.find_by_name(group_name)
  user_group.members << member
end

Then /^there should not exist a member belonging to "([^"]*)"$/ do |group_name|
  user_group = UserGroup.find_by_name(group_name)
  user_group.members.count == 0
end
