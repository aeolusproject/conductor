Given /^there is a user "([^"]*)"$/ do |name|
  unless User.find_by_login(name)
    FactoryGirl.create :user, :login => name, :email => "#{name}@example.com"
  end
end

Given /^there are (\d+) users$/ do |number|
  User.count.should == number.to_i
end

Then /^there should be (\d+) users?$/ do |number|
  User.count.should == number.to_i
end

When /^(?:|I )check "([^"]*)" user$/ do |user_name|
  user = User.find_by_login(user_name)
  check("user_checkbox_#{user.id}")
end
