Given /^there is a deployment named "([^"]*)" belonging to "([^"]*)" owned by "([^"]*)"$/ do |deployment_name, deployable_name, owner_name|
  user = FactoryGirl.create(:user, :username => owner_name, :last_name => owner_name)
  @deployment = Factory.create(:deployment, {:name => deployment_name, :pool => Pool.first, :owner => user})
  instance = Factory.create(:instance, {:deployment => @deployment})
  @deployment.instances << instance
  @deployment.save
  mock_deltacloud
end

Given /^there are some deployments$/ do
  @deployments = []
  2.times { @deployments << FactoryGirl.create(:deployment, { :pool => Pool.first, :owner => @user }) }
end

Given /^there is a deployment$/ do
  @deployment = FactoryGirl.create(:deployment, { :pool => Pool.first, :owner => @user })
end


Given /^the specified deployment does not exist in the system$/ do
  @deployment = FactoryGirl.build(:deployment, { :id => -1 })
end

When /^I check "([^"]*)" deployment/ do |name|
  deployment = Deployment.find_by_name(name)
  check("deployment_checkbox_#{deployment.id}")
end

Given /^there are (\d+) deployments$/ do |arg1|
  Deployment.all.each {|i| i.destroy}
  arg1.to_i.times do |i|
    FactoryGirl.create :deployment, :name => "deployment#{i}"
  end
end

Then /^I should see (\d+) deployments in JSON format$/ do |arg1|
  data = ActiveSupport::JSON.decode(page.source)
  data.length.should == arg1.to_i
end

Given /^a deployment "([^"]*)" exists$/ do |arg1|
  @deployment = Deployment.find_by_name(arg1)
  if not @deployment
    @deployment = FactoryGirl.create(:deployment, :name => arg1)
    instance = Factory.create(:instance, {:deployment => @deployment})
    @deployment.instances << instance
  end
  mock_deltacloud
  @deployment
end

Given /^the deployment "([^"]*)" has an instance named "([^"]*)"$/ do |d_name, i_name|
  deployment = Deployment.find_by_name(d_name)
  deployment.instances << FactoryGirl.create(:instance, :name => i_name, :pool => deployment.pool)
end

Given /^deployment "([^"]*)" is "([^"]*)"$/ do |arg1, arg2|
  Deployment.find_by_name(arg1).update_attribute(:state, arg2)
end

Given /^"([^"]*)" deployment's provider is not accessible$/ do |arg1|
  # FIXME: didn't find a way how to create an inaccessible provider
  # cleanly
  provider = @deployment.provider
  provider.update_attribute(:url, 'http://localhost:3002/invalid_api')
  ProviderAccount.any_instance.stub(:connect).and_return(nil)
end

When /^I am viewing the deployment "([^"]*)"$/ do |arg1|
  visit deployment_url(Deployment.find_by_name(arg1))
end

Then /^I should see deployment "([^"]*)" in JSON format$/ do |arg1|
  depl = Deployment.find_by_name(arg1)
  data = ActiveSupport::JSON.decode(page.source)
  data['name'].should == depl.name
end

When /^I create a deployment$/ do
  deployment = Factory.build :deployment
  deployment.pool.save!
  visit(deployments_url('deployment[name]' => deployment.name,
        'deployment[pool_id]' => deployment.pool.id, 'deployment[deployable_xml]' => deployment[:deployable_xml]))
end

Then /^I should get back a deployment in JSON format$/ do
  data = ActiveSupport::JSON.decode(page.source)
  data.should_not be_blank
end

Then /^I should get back a partial$/ do
  page.source.should_not match('<html')
  page.source.should_not match('Copyright')
  page.source.should_not == ""
  page.source.should match('<')
end

When /^I stop "([^"]*)" deployment$/ do |arg1|
  visit multi_stop_deployments_url('deployments_selected[]' => Deployment.find_by_name(arg1).id)
end

Given /^deployement "([^"]*)" has associated event "([^"]*)"$/ do |arg1, arg2|
  depl = Deployment.find_by_name(arg1)
  depl.events << Event.create(
    :source => depl,
    :event_time => DateTime.now,
    :summary => arg2
  )
end
