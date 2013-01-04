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

Given /^there are these pool families:$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:pool_family, :name => hash['name'])
  end
end

Given /^there is a pool family named "([^\"]*)"$/ do |name|
  @pool_family = FactoryGirl.create(:pool_family, :name => name)
  step %{there are no images in "#{@pool_family.name}" pool family}
end

Given /^there is a pool family named "([^\"]*)" with a pool named "([^\"]*)"$/ do |pool_family, pool|
  @pool_family = FactoryGirl.create(:pool_family, :name => pool_family)
  @pool = FactoryGirl.create(:pool, :name => pool, :pool_family => @pool_family)
  step %{there are no images in "#{@pool_family.name}" pool family}
end

Given /^there are no images in "([^\"]*)" pool family$/ do |name|
  PoolFamily.find_by_name(name).base_images.destroy
end

Given /^there is not a pool family named "([^"]*)"$/ do |name|
  pool_family = PoolFamily.find_by_name(name)
  if pool_family then pool_family.destroy end
end

Then /^I should have a pool family named "([^\"]*)"$/ do |name|
  PoolFamily.find_by_name(name).should_not be_nil
end

When /^(?:|I )check "([^"]*)" pool family$/ do |name|
  poolfamily = PoolFamily.find_by_name(name)
  check("pool_family_checkbox_#{poolfamily.id}")
end

Then /^there should not exist a pool family named "([^\"]*)"$/ do |name|
  PoolFamily.find_by_name(name).should be_nil
end

Then /^there should be (\d+) provider accounts assigned to "([^\"]*)"$/ do |count,name|
  @pool_family = PoolFamily.find_by_name(name)
  @pool_family.provider_accounts.count == count
end

Given /^there is a provider account "([^"]*)" related to pool family "([^"]*)"$/ do |provider_account, pool_family|
  @pool_family = PoolFamily.find_by_name(pool_family)
  @provider_account = ProviderAccount.find_by_label(provider_account)
  @pool_family.provider_accounts |= [@provider_account]
end

When /^I check "([^"]*)" provider account$/ do |label|
  provider_account = ProviderAccount.find_by_label(label)
  check("provider_account_checkbox_#{provider_account.id}")
end

Then /^there should not exist a provider account assigned to "([^"]*)"$/ do |name|
  @pool_family = PoolFamily.find_by_name(name)
  @pool_family.provider_accounts.count == 0
end

Given /^I can view pool family "([^"]*)"$/ do |arg1|
  pool_family = PoolFamily.find_by_name(arg1)  || FactoryGirl.create(:pool_family, :name => arg1)
  perm = FactoryGirl.create(:pool_family_user_permission, :permission_object => pool_family, :entity => @user.entity)
end
