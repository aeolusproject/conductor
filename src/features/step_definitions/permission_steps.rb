Given /^a user "([^\"]*)" exists$/ do |login|
  @user = Factory(:user, :login => login)
end

Given /^there is not a permission for the user "([^\"]*)"$/ do |login|
  Permission.first(:include => 'user', :conditions => ['users.login = ?', login]).should be_nil
end

Given /^there is a permission for the user "([^\"]*)"$/ do |login|
  @admin_permission = Factory(:admin_permission, :user_id => @user.id)
end

Given /^I delete the permission$/ do
  click_button "delete_#{@admin_permission.id}"
end
