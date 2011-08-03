Given /^there are these pool families:$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:pool_family, :name => hash['name'])
  end
end

Given /^there is a pool family named "([^\"]*)"$/ do |name|
  @pool_family = FactoryGirl.create(:pool_family, :name => name)
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
  @pool_family.provider_accounts << @provider_account
end

When /^I check "([^"]*)" provider account$/ do |label|
  provider_account = ProviderAccount.find_by_label(label)
  check("provider_account_checkbox_#{provider_account.id}")
end

Then /^there should not exist a provider account assigned to "([^"]*)"$/ do |name|
  @pool_family = PoolFamily.find_by_name(name)
  @pool_family.provider_accounts.count == 0
end
