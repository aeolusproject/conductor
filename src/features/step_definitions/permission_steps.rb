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
Given /^a user "([^\"]*)" exists$/ do |login|
  @user = FactoryGirl.create(:user, :login => login)
end

Given /^there is not a permission for the user "([^\"]*)"$/ do |login|
  Permission.first(:include => ['entity' => ['session_entities' => 'user']], :conditions => ['users.login = ?', login]).should be_nil
end

Given /^there is a permission for the user "([^\"]*)"$/ do |login|
  @admin_permission = FactoryGirl.create(:admin_permission, :user_id => @user.id)
end

Given /^there is a permission for the user "([^\"]*)" on the pool "([^\"]*)"$/ do |login, pool_name|
  @pool_user_permission = FactoryGirl.create(:pool_user_permission, :entity_id => @user.entity.id,
                                         :permission_object => Pool.find_by_name(pool_name))
end

Given /^there is a permission for the user "([^\"]*)" on the pool family "([^\"]*)"$/ do |login, pool_family_name|
  @pool_family_admin_permission = FactoryGirl.create(:pool_family_admin_permission, :entity_id => @user.entity.id,
                                         :permission_object => PoolFamily.find_by_name(pool_family_name))
end

Given /^I delete the permission$/ do
  check "permission_checkbox_#{@pool_user_permission.id}"
  click_button "revoke_button"
end

When /^(?:|I )select "([^"]*)" role for the user "([^"]*)"$/ do |role_name, user_name|
  user = User.find_by_login(user_name)
  select(role_name, :from => "entity_role_selected_#{user.entity.id}")
end
