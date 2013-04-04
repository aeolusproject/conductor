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
Given /there's no role/ do
  Alberich::Role.destroy_all
end

Given /there's a list of roles/ do
  @initial_num_roles = Alberich::Role.count
end

Given /^a role "([^"]*)" exists$/ do |role_name|
  Alberich::Role.create(:name => role_name, :scope => Alberich::BasePermissionObject.to_s)
end

Given /^there should be a role named "([^\"]*)"$/ do |name|
  Alberich::Role.find_by_name(name).should_not == nil
end

Given /^there are (\d+) roles$/ do |number|
  Alberich::Role.count.should == number.to_i
end

Given /^there are (\d+) more roles$/ do |number|
  Alberich::Role.count.should == @initial_num_roles + number.to_i
end

Given /^there are (\d+) fewer roles$/ do |number|
  Alberich::Role.count.should == @initial_num_roles - number.to_i
  (@initial_num_roles + Alberich::Role.count).should == number.to_i
end

When /^I delete the role "(.*?)"$/ do |role_name|
  role = Alberich::Role.find_by_name(role_name)
  click_link("destroy_role_#{role.id}")
end

Then /^there should only be (\d+) roles$/ do |number|
  Alberich::Role.count.should == number.to_i
end

Then /^there should be (\d+) more roles$/ do |number|
  Alberich::Role.count.should == @initial_num_roles + number.to_i
end

Then /^there should be (\d+) fewer roles$/ do |number|
  Alberich::Role.count.should == (@initial_num_roles - number.to_i)
end
