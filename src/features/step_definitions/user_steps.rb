Given /^there is a user "([^"]*)"$/ do |name|
  @user = User.find_by_login(name)
end
