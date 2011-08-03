Given /^a suggested deployable "([^"]*)" exists$/ do |arg1|
  FactoryGirl.create :suggested_deployable, :name => arg1
end

When /^I check "([^"]*)" suggested deployable$/ do |arg1|
  dep = SuggestedDeployable.find_by_name(arg1)
  check("suggested_deployable_checkbox_#{dep.id}")
end

Then /^there should be only (\d+) suggested deployables$/ do |arg1|
  SuggestedDeployable.count.should == arg1.to_i
end
