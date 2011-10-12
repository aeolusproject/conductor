Given /^a catalog entry "([^"]*)" exists$/ do |arg1|
  FactoryGirl.create :catalog_entry, :name => arg1
end

When /^I check "([^"]*)" catalog entry$/ do |arg1|
  dep = CatalogEntry.find_by_name(arg1)
  check("catalog_entry_checkbox_#{dep.id}")
end

Then /^there should be only (\d+) catalog entries$/ do |arg1|
  CatalogEntry.count.should == arg1.to_i
end

Given /^a catalog entry "([^"]*)" exists for "([^"]*)" catalog$/ do |arg1, catalog_name|
  catalog = Catalog.find_by_name(catalog_name) || FactoryGirl.create(:catalog, :name => catalog_name)
  FactoryGirl.create :catalog_entry, :name => arg1, :catalog => catalog
end
