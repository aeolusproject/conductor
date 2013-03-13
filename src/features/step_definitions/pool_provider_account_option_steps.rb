#
#   Copyright 2013 Red Hat, Inc.
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

Then /^I should see score "(.*?)" for provider account with label "(.*?)"$/ do |score, provider_account_label|
  found = false
  all("tr").each do |tr|
    if tr.has_content?(provider_account_label) && tr.has_content?(score)
      found = true
    end
  end
  assert found
end

Given /^a pool "([^"]*)" with provider account "([^"]*)" exists$/ do |pool_name, provider_account_label|
  pool_family = FactoryGirl.create(:pool_family)
  provider_account = FactoryGirl.create(:mock_provider_account, :label => provider_account_label)
  pool_family.provider_accounts = [provider_account]
  quota = FactoryGirl.create(:quota)
  Pool.create!(:name => pool_name, :pool_family => pool_family, :quota => quota, :enabled => true)
end

Given /^a provider account score exists for pool "(.*?)" and provider account "(.*?)"$/ do |pool_name, provider_account_label|
  pool = Pool.find_by_name(pool_name)
  provider_account = pool.pool_family.provider_accounts.find_by_label(provider_account_label)
  PoolProviderAccountOption.create!(:pool => pool, :provider_account => provider_account, :score => 42)
end
