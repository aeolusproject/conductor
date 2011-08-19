Given /^there is a "([^"]*)" catalog$/ do |name|
  FactoryGirl.create :catalog, :name => name
end