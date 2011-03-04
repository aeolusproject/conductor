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

Given /^there are these templates:$/ do |table|
  table.hashes.each do |hash|
    @template = Factory.build(:template, :name => hash['name'],
                               :platform => hash['platform'])
    @template.save!
    @template.platform_version = hash['platform_version']
    @template.architecture = hash['architecture']
    @template.summary = hash['summary']
    @template.save!
  end
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
  @template = Factory.build :template, :name => arg1
  @template.save!
  image = Factory.build(:image, :template => @template)
  image.save!
end

When /^I choose this template$/ do
  click_link(@template.name)
end
Given /^there is Amazon AWS provider account$/ do
  account = Factory.build(:ec2_provider_account)
  account.save!
end

Given /^there is Amazon AWS build for this template$/ do
  Image.build(@template, ProviderType.find_by_codename("ec2"))
end

Given /^there is Amazon AWS provider with no builds$/ do
  provider = Factory.build(:ec2_provider_no_builds)
  provider.save!
end

Given /^there is an imported template$/ do
  @template = Factory.build :template, :name => name, :imported => true
  @template.save!
end

Given /^has package "([^"]*)"$/ do |arg1|
  @template.add_packages [:arg1]
end

When /^I edit the template$/ do
  visit edit_image_factory_template_url(@template)
end

When /^(?:|I )check "([^"]*)" template$/ do |template_name|
  template = Template.find_by_name(template_name)
  check("selected_#{template.id}")
end
