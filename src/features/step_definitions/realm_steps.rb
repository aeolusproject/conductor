Given /there's no realm/ do
  FrontendRealm.destroy_all
end

Given /^a realm "([^"]*)" exists$/ do |realm_name|
  FrontendRealm.create(:name => realm_name)
end

Given /^a provider "([^"]*)" exists$/ do |name|
  Factory(:mock_provider, :name => name)
end

Given /^there is a realm "([^"]*)"$/ do |name|
  FrontendRealm.find_by_name(name).should_not == nil
end

Given /^there are (\d+) realms$/ do |number|
  FrontendRealm.count.should == number.to_i
end

When /^(?:|I )check "([^"]*)" realm$/ do |realm_name|
  realm = FrontendRealm.find_by_name(realm_name)
  check("realm_checkbox_#{realm.id}")
end

Then /^there should be only (\d+) realms$/ do |number|
  FrontendRealm.count.should == number.to_i
end
