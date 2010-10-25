def user
  @user ||= Factory :user
end

def login(login, password)
  user
  visit path_to("the login page")
  fill_in "Username", :with => login
  fill_in "Password", :with => password
  click_button "Login"
end

Given /^I am a registered user$/ do
  user
end

When /^I login$/ do
  login(user.login, user.password)
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
  click_link "#{user.first_name} #{user.last_name}"
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
