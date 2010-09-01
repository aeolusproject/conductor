Given /^there is not a provider named "([^\"]*)"$/ do |name|
  Provider.find_by_name(name).should be_nil
end

Given /^there is a provider named "([^\"]*)"$/ do |name|
  @provider = Factory(:mock_provider, :name => name)
end

Then /^I should have a provider named "([^\"]*)"$/ do |name|
  Provider.find_by_name(name).should_not be_nil
end

When /^I follow provider settings link$/ do
  within '#provider-tabs' do |scope|
    scope.click_link "Settings"
  end
end

When /^I delete provider$/ do
  click_button "Delete provider"
end


Given /^there are these providers:$/ do |table|
  table.hashes.each do |hash|
    Factory(:mock_provider, :name => hash['name'])
  end
end
