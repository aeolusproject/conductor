Given /^there is a user "([^"]*)"$/ do |name|
 User.find_by_login(name).should_not == nil
end

Given /^there are (\d+) users$/ do |number|
  User.all.size.should == number.to_i
end

Then /^there should only be (\d+) users$/ do |number|
  User.all.size.should == number.to_i
end
