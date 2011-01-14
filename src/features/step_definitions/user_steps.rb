Given /^there is a user "([^"]*)"$/ do |name|
  unless User.find_by_login(name)
    Factory :user, :login => name, :email => "#{name}@example.com"
  end
end

Given /^there are (\d+) users$/ do |number|
  User.count.should == number.to_i
end

Then /^there should only be (\d+) users$/ do |number|
  User.count.should == number.to_i
end
