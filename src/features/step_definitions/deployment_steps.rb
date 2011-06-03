Given /^there is a deployment named "([^"]*)" belonging to "([^"]*)" owned by "([^"]*)"$/ do |deployment_name, deployable_name, owner_name|
  user = Factory(:user, :login => owner_name, :last_name => owner_name)
  deployable = LegacyDeployable.create!(:name => deployable_name, :owner => user)
  @deployment = Deployment.create!({:name => deployment_name, :pool => Pool.first, :owner => user, :legacy_deployable_id => deployable.id})
end

When /^I check "([^"]*)" deployment/ do |name|
  deployment = Deployment.find_by_name(name)
  check("deployment_checkbox_#{deployment.id}")
end

Given /^there are (\d+) deployments$/ do |arg1|
  Deployment.all.each {|i| i.destroy}
  arg1.to_i.times do |i|
    Factory :deployment, :name => "deployment#{i}"
  end
end

Then /^I should see (\d+) deployments in JSON format$/ do |arg1|
  data = ActiveSupport::JSON.decode(response.body)
  data.length.should == arg1.to_i
end

Given /^a deployment "([^"]*)" exists$/ do |arg1|
  Factory(:deployment, :name => arg1) unless Deployment.find_by_name(arg1)
end

When /^I am viewing the deployment "([^"]*)"$/ do |arg1|
  visit deployment_url(Deployment.find_by_name(arg1))
end

Then /^I should see deployment "([^"]*)" in JSON format$/ do |arg1|
  depl = Deployment.find_by_name(arg1)
  data = ActiveSupport::JSON.decode(response.body)
  data['deployment']['name'].should == depl.name
end

When /^I create a deployment$/ do
  deployment = Factory.build :deployment
  deployment.pool.save!
  deployment.legacy_deployable.save!
  visit(deployments_url, :post, 'deployment[name]' => deployment.name,
        'deployment[pool_id]' => deployment.pool.id, 'deployment[legacy_deployable_id]' => deployment.legacy_deployable.id)
end

Then /^I should get back a deployment in JSON format$/ do
  data = ActiveSupport::JSON.decode(response.body)
  data['deployment'].should_not be_nil
end

Then /^I should get back a partial$/ do
  response.body.should_not match('<html')
  response.body.should_not match('Copyright')
  response.body.should_not == ""
  response.body.should match('<')
end

When /^I stop "([^"]*)" deployment$/ do |arg1|
  visit(multi_stop_deployments_url, :post, 'deployments_selected[]' => Deployment.find_by_name(arg1).id)
end
