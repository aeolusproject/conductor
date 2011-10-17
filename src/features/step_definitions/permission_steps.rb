Given /^a user "([^\"]*)" exists$/ do |login|
  @user = FactoryGirl.create(:user, :login => login)
end

Given /^there is not a permission for the user "([^\"]*)"$/ do |login|
  Permission.first(:include => 'user', :conditions => ['users.login = ?', login]).should be_nil
end

Given /^there is a permission for the user "([^\"]*)"$/ do |login|
  @admin_permission = FactoryGirl.create(:admin_permission, :user_id => @user.id)
end

Given /^there is a permission for the user "([^\"]*)" on the pool "([^\"]*)"$/ do |login, pool_name|
  @pool_user_permission = FactoryGirl.create(:pool_user_permission, :user_id => @user.id,
                                         :permission_object => Pool.find_by_name(pool_name))
end

Given /^I delete the permission$/ do
  check "permission_checkbox_#{@pool_user_permission.id}"
  click_button "revoke_button"
end

When /^(?:|I )select "([^"]*)" role for the user "([^"]*)"$/ do |role_name, user_name|
  user = User.find_by_login(user_name)
  select(role_name, :from => "user_role_selected_#{user.id}")
end
