Given /^there is an assembly named "([^"]*)"$/ do |name|
  Assembly.create!(:name => name, :architecture => 'x86_64', :owner => user)
end

Given /^there is an assembly named "([^"]*)" belonging to "([^"]*)"$/ do |assembly_name, deployable_name|
  deployable = Deployable.find_by_name(deployable_name)
  deployable.assemblies.create!(:name => assembly_name, :architecture => 'x86_64', :owner => user)
#  Assembly.create!(:name => assembly, :architecture => 'x86_64', :deployable => Deployable.find_by_name(deployable))
end

Given /^there is an assembly named "([^"]*)" belonging to "([^"]*)" template$/ do |assembly_name, template_name|
  template = Template.find_by_name(template_name)
  assembly = Assembly.find_by_name(assembly_name)
  unless assembly.nil?
    template.assemblies << assembly
  else
    template.assemblies.create!(:name => assembly_name, :architecture => 'x86_64')
  end
#  Assembly.create!(:name => assembly, :architecture => 'x86_64', :deployable => Deployable.find_by_name(deployable))
end

When /^I check the "([^"]*)" assembly$/ do |name|
  assembly = Assembly.find_by_name(name)
  check("assembly_checkbox_#{assembly.id}")
end
