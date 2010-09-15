Given /^There is a mock pulp repository$/ do
  dir = File.join(Rails.root, 'spec', 'fixtures')
  hydra = Typhoeus::Hydra.hydra
  hydra.stub(:get, "http://pulptest/repositories/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'repositories.json'))))
  hydra.stub(:get, "http://pulptest/repositories/jboss/packagegroups/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'packagegroups.json'))))
  hydra.stub(:get, "http://pulptest/repositories/jboss/packages/").and_return(
    Typhoeus::Response.new(:code => 200,
                           :body => File.read(File.join(dir, 'packages.json'))))

end

Given /^There is a "([^"]*)" template$/ do |name|
  @template = Template.new
  @template.xml.name = name
  @template.save_xml!
end

Given /^there is a package group$/ do
  RepositoryManager.new.all_groups.should have_at_least(1).item
end

Given /^no package is selected$/ do
  @template.xml.packages = []
end

Given /^there is one selected package$/ do
  pkg = RepositoryManager.new.all_packages.first
  @template.xml.packages = []
  @template.xml.add_package(pkg['name'], nil)
  @template.save_xml!
end

# "I jump" is used instead of "I am" because "I am" is already defined in
# web_steps.rb and in this case I have to use @template as parameter which "I
# am" doesn't support
Given /^I jump on the "([^"]*)" template software page$/ do |name|
  visit url_for :action => 'software', :controller => 'templates', :id => @template
end

Then /^I should have a template named "([^"]*)"$/ do |name|
  Template.first(:order => 'created_at DESC').xml.name.should eql(name)
end
