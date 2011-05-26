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
  visit instance_url(mock_instance)
end

When /^I am viewing the pending instance detail$/ do
  visit instance_url(pending_instance)
end

When /^I am viewing the mock instance$/ do
  visit instance_url(mock_instance)
end

When /^I manually go to the key action for this instance$/ do
  visit key_instance_url(pending_instance)
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

Given /^there is a "([^"]*)" stopped instance$/ do |name|
  Factory :instance, :name => name, :state => Instance::STATE_STOPPED
end

Given /^there is an uploaded image for a template$/ do
  Factory :provider_image
end

Given /^there is "([^"]*)" conductor hardware profile$/ do |name|
  Factory :mock_hwp2, :name => name
end

Given /^there is "([^"]*)" frontend realm$/ do |name|
  Factory :frontend_realm, :name => name
end

Given /^there is "([^"]*)" pool$/ do |arg1|
  Factory :pool, :name => arg1
end


When /^I check "([^"]*)" instance$/ do |name|
  inst = Instance.find_by_name(name)
  check("instance_checkbox_#{inst.id}")
end

Given /^there are the following instances:$/ do |table|
  table.hashes.each do |hash|
    Factory(:instance, :name => hash['name'],
                       :external_key => hash['external_key'],
                       :state => hash['state'],
                       :public_addresses => hash['public_addresses'],
                       :private_addresses => hash['private_addresses'])
  end
end

Given /^there is the following instance with a differently-named owning user:$/ do |table|
  table.hashes.each do |hash|
    Factory(:other_owner_instance, :name => hash['name'],
                       :external_key => hash['external_key'],
                       :state => hash['state'],
                       :public_addresses => hash['public_addresses'],
                       :private_addresses => hash['private_addresses'])
  end
end


Given /^there are (\d+) instances$/ do |count|
  Instance.all.each {|i| i.destroy}
  count.to_i.times do |i|
    Factory :mock_pending_instance, :name => "inst#{i}"
  end
end

Given /^I accept JSON$/ do
  header 'Accept', 'application/json'
end

Given /^I request XHR$/ do
  header 'X-Requested-With', 'XMLHttpRequest'
end

Then /^I should see (\d+) instances in JSON format$/ do |count|
  ActiveSupport::JSON.decode(response.body).length.should == count.to_i
end

When /^I create mock instance$/ do
  inst = Factory.build :mock_running_instance
  visit instances_url, :post, 'instance[name]' => inst.name, 'instance[template_id]' => inst.template_id
end

Then /^I should see mock instance in JSON format$/ do
  data = ActiveSupport::JSON.decode(response.body)
  data['instance']['name'].should == mock_instance.name
end

Then /^I should get back instance in JSON format$/ do
  data = ActiveSupport::JSON.decode(response.body)
  data['instance'].should_not be_nil
end

When /^I stop "([^"]*)" instance$/ do |arg1|
  inst = Instance.find_by_name(arg1)
  visit multi_stop_instances_url, :post, 'instance_selected[]' => inst.id
end

Then /^I should get back JSON object with success and errors$/ do
  data = ActiveSupport::JSON.decode(response.body)
  data['success'].should_not be_nil
  data['errors'].should_not be_nil
end
