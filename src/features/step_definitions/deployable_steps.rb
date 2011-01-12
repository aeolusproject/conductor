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
  Deployable.create!(:name => name)
end

When /^I check the "([^"]*)" deployable$/ do |name|
  deployable = Deployable.find_by_name(name)
  check("deployable_checkbox_#{deployable.id}")
end
