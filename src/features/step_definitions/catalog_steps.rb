Given /^there is a "([^"]*)" catalog$/ do |name|
  FactoryGirl.create :catalog, :name => name
end

When /^I check "([^"]*)" catalog$/ do |arg1|
  catalog = Catalog.find_by_name(arg1)
  check("catalog_checkbox_#{catalog.id}")
end
