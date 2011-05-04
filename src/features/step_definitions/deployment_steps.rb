Given /^there is a deployment named "([^"]*)" belonging to "([^"]*)" owned by "([^"]*)"$/ do |deployment_name, deployable_name, owner_name|
  user = Factory(:user, :login => owner_name)
  deployable = Deployable.create!(:name => deployable_name, :owner => user)
  @deployment = Deployment.create!({:name => deployment_name, :pool => Pool.first, :owner => user, :deployable_id => deployable.id})
end

When /^I check "([^"]*)" deployment/ do |name|
  deployment = Deployment.find_by_name(name)
  check("deployment_checkbox_#{deployment.id}")
end
