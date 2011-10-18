def user
  @user ||= FactoryGirl.create :user
end

def admin_user
  @user ||= FactoryGirl.create :admin_user
end

def login(login, password)
  user
  visit path_to("the login page")
  fill_in "login", :with => login
  fill_in "password", :with => password
  click_button "login-btn"
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

When /^I login as authorised user$/ do
  admin_user = @admin_permission.user
  login(admin_user.login, admin_user.password)
  page.should have_content('Login successful!')
end

Given /^I am a new user$/ do
  signup
end

Given /^I am logged in$/ do
  page.driver.header 'Accept-Language', 'en-US'
  login(user.login, user.password)
  page.should have_content('Login successful!')
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

When /^I log out$/ do
 visit '/logout'
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

When /^I fill login "([^\"]*)" and incorrect password$/ do |login|
  login(login, "wrong_password")
end

Then /^"([^"]*)" user failed login count is more than zero$/ do |login|
  user = User.find_by_login(login)
  user.failed_login_count.should > 0
end
