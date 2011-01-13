def mock_instance
  @mock_instance ||= Factory :mock_running_instance
end

def pending_instance
  @pending_instance ||= Factory :mock_pending_instance
end

Given /^a mock running instance exists$/ do
  mock_instance.instance_key = Factory :mock_instance_key, :instance_key_owner => mock_instance
end

Given /^a mock pending instance exists$/ do
  pending_instance
end

Given /^I am viewing the mock instance detail$/ do
  visit resources_instance_url(mock_instance)
end

When /^I am viewing the pending instance detail$/ do
  visit resources_instance_url(pending_instance)
end

When /^I manually go to the key action for this instance$/ do
  visit key_resources_instance_url(pending_instance)
end

Given /^I see "([^"]*)"$/ do |text|
  response.should contain(text)
end

Then /^I should see the Save dialog for a (.+) file$/ do |filetype|
  response.headers["Content-Disposition"].should
  match(/^attachment;\sfilename=.*#{filetype}$/)
end

Given /^there is a "([^"]*)" instance$/ do |name|
  Factory :instance, :name => name
end

Given /^there is a "([^"]*)" failed instance$/ do |name|
  Factory :instance, :name => name, :state => Instance::STATE_ERROR
end

Given /^there is a "([^"]*)" running instance$/ do |name|
  Factory :instance, :name => name, :state => Instance::STATE_RUNNING
end

Given /^there is an uploaded image for a template$/ do
  Factory :replicated_image
end

Given /^there is "([^"]*)" aggregator hardware profile$/ do |name|
  Factory :mock_hwp2, :name => name
end

Given /^there is "([^"]*)" aggregator realm$/ do |name|
  Factory :frontend_realm, :provider_id => nil, :name => name
end

Given /^there is "([^"]*)" pool$/ do |arg1|
  Factory :pool, :name => arg1
end

When /^I check "([^"]*)" instance$/ do |name|
  inst = Instance.find_by_name(name)
  check("inst_ids_#{inst.id}")
end
