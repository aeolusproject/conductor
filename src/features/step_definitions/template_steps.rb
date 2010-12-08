Given /^There is a mock pulp repository$/ do
  dir = File.join(Rails.root, 'spec', 'fixtures')
  hydra = Typhoeus::Hydra.hydra
  hydra.stub(:get, "http://pulptest/repositories/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'repositories.json'))))
  hydra.stub(:get, "http://pulptest/repositories/fedora/packagegroups/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'packagegroups.json'))))
  hydra.stub(:get, "http://pulptest/repositories/fedora/packages/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'packages.json'))))
  hydra.stub(:get, "http://pulptest/repositories/fedora/packagegroupcategories/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'packagegroupcategories.json'))))

end

Given /^there is a "([^"]*)" template$/ do |name|
  @template = Factory.build :template, :name => name
  @template.save!
end

Given /^there is a package group$/ do
  RepositoryManager.new.all_groups.should have_at_least(1).item
end

Given /^no package is selected$/ do
  @template.packages = []
end

Given /^there is one selected package$/ do
  pkg = RepositoryManager.new.all_packages.first
  @template.packages = [pkg['name']]
  @template.save!
end

# "I jump" is used instead of "I am" because "I am" is already defined in
# web_steps.rb and in this case I have to use @template as parameter which "I
# am" doesn't support
Given /^I jump on the "([^"]*)" template software page$/ do |name|
  visit url_for(:action => 'software', :controller => 'templates', :id => @template)
end

Then /^I should have a template named "([^"]*)"$/ do |name|
  Template.first(:order => 'created_at DESC').xml.name.should eql(name)
end

Then /^the "([^"]*)" field by name should contain "([^"]*)"$/ do |field, value|
  field_value = field_named(field).value
  if field_value.respond_to? :should
    field_value.should =~ /#{value}/
  else
    assert_match(/#{value}/, field_value)
  end
end

Then /^the page should contain "([^"]*)" selector$/ do |selector|
  response.should have_selector(selector)
end

Then /^the page should not contain "([^"]*)" selector$/ do |selector|
  response.should_not have_selector(selector)
end

Then /^I should see "([^"]*)" followed by "([^"]*)"$/ do |arg1, arg2|
  # webrat doesn't support checking order of elements on a page, so
  # this seems to be siplest check
  (response.body =~ /#{Regexp.escape(arg1)}.*#{Regexp.escape(arg2)}/m).should_not be_nil
end

Given /^there is a "([^"]*)" build$/ do |arg1|
  template = Factory.build :template, :name => arg1
  template.save!
  image = Factory.build(:image, :template => template)
  image.save!
end

When /^I choose this template$/ do
  choose("ids__#{@template.id}")
end

Given /^there is ec2 cloud account$/ do
  account = Factory.build(:ec2_cloud_account)
  account.save!
end

Given /^there is ec2 build for this template$/ do
  Image.build(@template, 'ec2')
end

Given /^there is an imported template$/ do
  @template = Factory.build :template, :name => name, :imported => true
  @template.save!
end
