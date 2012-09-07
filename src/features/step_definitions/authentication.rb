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
def user
  @user ||= FactoryGirl.create :user
end

def admin_user
  user ||= FactoryGirl.create :admin_user
end

def login(username, password)
  user
  visit path_to("the login page")
  fill_in "username", :with => username
  fill_in "password", :with => password
  click_button "login_btn"
end

def signup
  visit path_to("the new account page")
  fill_in "Choose a username", :with => 'newuser'
  fill_in "Choose a password", :with => 'password'
  fill_in "Confirm password", :with => 'password'
  fill_in "First name", :with => 'Unprivileged'
  fill_in "Last name", :with => "User"
  fill_in "E-mail", :with => "testuser@example.com"
  click_button "Save"
end

Given /^I am a registered user$/ do
  user
end

Given /^I am an authorised user$/ do
  @admin_user = FactoryGirl.create :admin_user
  @user = @admin_user
  @admin_permission = FactoryGirl.create :admin_permission, :entity => @user.entity
end


When /^I login$/ do
  login(user.username, user.password)
end

When /^I login as authorised user$/ do
  login(@admin_user.username, @admin_user.password)
end

Given /^I am a new user$/ do
  signup
end

Given /^I am logged in$/ do
  # Warden test helper method
  login_as user
  visit path_to("the homepage")
end

Given /^I have successfully logged in$/ do
  page.driver.header 'Accept-Language', 'en-US'
  login(user.username, user.password)
end

Given /^there are not any roles$/ do
  Role.destroy_all
end

When /^I forget to enter my password$/ do
  login(user.username, nil)
end

When /^I want to edit my profile$/ do
  click_link "My Account"
  click_link "Edit"
end

When /^I log out$/ do
 visit '/logout'
end

Then /^I should have one private pool named "([^\"]*)"$/ do |username|
  Pool.find_by_name(username).should_not be_nil
  Pool.find_by_name(username).permissions.size.should == 1
end

Then /^there should not be user with username "([^\"]*)"$/ do |username|
  User.find_by_username(username).should be_nil
end

When /^I enter a string of length "([^"]*)" into "([^"]*)"$/ do |length, field_name|
  string = 'x' * length.to_i
  When "I fill in \"#{field_name}\" with \"#{string}\""
end

When /^I login with incorrect credentials$/ do
  login("wrong_username", "wrong_password")
end

When /^I fill username "([^\"]*)" and incorrect password$/ do |username|
  login(username, "wrong_password")
end

Then /^"([^"]*)" user failed login count is more than zero$/ do |username|
  user = User.find_by_username(username)
  user.failed_login_count.should > 0
end
