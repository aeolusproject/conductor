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
Given /^there is a user "([^"]*)"$/ do |name|
  unless User.find_by_username(name)
    FactoryGirl.create :user, :username => name, :email => "#{name}@example.com"
  end
end

Given /^there are (\d+) users$/ do |number|
  User.count.should == number.to_i
end

Given /^user "([^"]*)" has valid password reset token "([^"]*)"$/ do |username, password_reset_token|
  user = User.find_by_username(username)
  user.password_reset_token = password_reset_token
  user.password_reset_sent_at = Time.zone.now
  user.save
end

Then /^there should be (\d+) users?$/ do |number|
  User.count.should == number.to_i
end

When /^(?:|I )check "([^"]*)" user$/ do |user_name|
  user = User.find_by_username(user_name)
  check("user_checkbox_#{user.id}")
end
