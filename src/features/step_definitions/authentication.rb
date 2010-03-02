def user
  @user ||= Factory :user
end

def login(login, password)
  user
  visit path_to("the login page")
  fill_in "Login", :with => login
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

When /^I forget to enter my password$/ do
  login(user.login, nil)
end

When /^I want to edit my profile$/ do
  click_link "Hi, #{user.login}"
  response.should contain("User Profile for #{user.login}")
end

Then /^I should be logged out$/ do
  UserSession.find.should == nil
end
