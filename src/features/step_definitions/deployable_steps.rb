Then /^there should be no deployables$/ do
  Deployable.count.should == 0
end

Given /^there are no deployables$/ do
  Deployable.count.should == 0
end

Then /^I should have a deployable named "([^"]*)"$/ do |name|
  Deployable.find_by_name(name).should_not be_nil
end

Given /^there is a deployable named "([^"]*)"$/ do |name|
  @deployable = Deployable.create!(:name => name, :owner => user)
end

When /^I check the "([^"]*)" deployable$/ do |name|
  deployable = Deployable.find_by_name(name)
  check("deployable_checkbox_#{deployable.id}")
end

Given /^there are deployment named "([^"]*)" belongs to "([^"]*)"$/ do |deployment_name, deployable_name|
  Factory(:deployment, :deployable => Deployable.find_by_name(deployable_name), :name => deployment_name)
end

Given /^there is a factory deployable named "([^"]*)"$/ do |arg1|
  Factory(:deployable, :name => arg1)
end

When /^I select default hardware profile for assemblies in "([^"]*)"$/ do |arg1|
  deployable = Deployable.find_by_name(arg1)
  deployable.assemblies.each do |a|
    select('mock_profile', :from => "hw_profiles_#{a.id}")
  end
end
