def user
  @user ||= Factory :user
end

def login(login, password)
  user
  visit path_to("the login page")
  fill_in "user_session[login]", :with => login
  fill_in "user_session[password]", :with => password
  click_button "Login"
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

When /^I login$/ do
  login(user.login, user.password)
end

Given /^I am a new user$/ do
  signup
end

Given /^I am logged in$/ do
  login(user.login, user.password)
  UserSession.find.should_not == nil
end

Given /^there are not any roles$/ do
  Role.destroy_all
end

When /^I forget to enter my password$/ do
  login(user.login, nil)
end

When /^I want to edit my profile$/ do
  click_link "My Account"
  click_link "Edit"
end

Then /^I should be logged out$/ do
  UserSession.find.should == nil
end

Then /^I should have one private pool named "([^\"]*)"$/ do |login|
  Pool.find_by_name(login).should_not be_nil
  Pool.find_by_name(login).permissions.size.should == 1
end

Then /^there should not be user with login "([^\"]*)"$/ do |login|
  User.find_by_login(login).should be_nil
end

When /^I enter a string of length "([^"]*)" into "([^"]*)"$/ do |length, field_name|
  valid_chars = [*('a'..'z')] + [*('A'..'Z')] + [*(1..9)] + ['_', '-']
  string = ""
  length.to_i.times { string << valid_chars[rand(valid_chars.length)] }
  When "I fill in \"#{field_name}\" with \"#{string}\""
end

When /^I login with incorrect credentials$/ do
  login("wrong_username", "wrong_password")
end
