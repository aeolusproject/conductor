Given /there's no role/ do
  Role.destroy_all
end

Given /there's a list of roles/ do
  @initial_num_roles = Role.count
end

Given /^a role "([^"]*)" exists$/ do |role_name|
  Role.create(:name => role_name, :scope => BasePermissionObject.to_s)
end

Given /^there should be a role named "([^\"]*)"$/ do |name|
  Role.find_by_name(name).should_not == nil
end

Given /^there are (\d+) roles$/ do |number|
  Role.count.should == number.to_i
end

Given /^there are (\d+) more roles$/ do |number|
  Role.count.should == @initial_num_roles + number.to_i
end

Given /^there are (\d+) fewer roles$/ do |number|
  Role.count.should == @initial_num_roles - number.to_i
  (@initial_num_roles + Role.count).should == number.to_i
end

When /^(?:|I )check "([^"]*)" role$/ do |role_name|
  role = Role.find_by_name(role_name)
  check("role_checkbox_#{role.id}")
end

Then /^there should only be (\d+) roles$/ do |number|
  Role.count.should == number.to_i
end

Then /^there should be (\d+) more roles$/ do |number|
  Role.count.should == @initial_num_roles + number.to_i
end

Then /^there should be (\d+) fewer roles$/ do |number|
  Role.count.should == (@initial_num_roles - number.to_i)
end
