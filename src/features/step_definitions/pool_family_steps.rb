Given /^there are these pool families:$/ do |table|
  table.hashes.each do |hash|
    Factory(:pool_family, :name => hash['name'])
  end
end

Given /^there is a pool family named "([^\"]*)"$/ do |name|
  @provider = Factory(:pool_family, :name => name)
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
