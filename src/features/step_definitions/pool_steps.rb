Given /^I am an authorised user$/ do
  @admin_permission = Factory :admin_permission
  @user = @admin_permission.user
end

Given /^I have Pool Creator permissions on a pool named "([^\"]*)"$/ do |name|
  @pool = Factory(:pool, :name => name)
  Factory(:pool_creator_permission, :user => @user, :permission_object => @pool)
end

Then /^there should be (\d+) pools$/ do |number|
  Pool.count.should == number.to_i
end

Given /^there is not a pool named "([^\"]*)"$/ do |name|
  Pool.find_by_name(name).should be_nil
end

Given /^a pool "([^"]*)" exists$/ do |pool_name|
  pool_family = PoolFamily.find_by_name('default') || Factory(:pool_family)
  quota = Factory(:quota)
  Pool.create!(:name => pool_name, :pool_family => pool_family, :quota => quota)
end

Given /^a pool "([^"]*)" exists with deployment "([^"]*)"$/ do |pool_name, deployment_name|
  pool_family = PoolFamily.find_by_name('default') || Factory(:pool_family)
  quota = Factory(:quota)
  pool = Pool.find_by_name(pool_name) || Pool.create!(:name => pool_name, :pool_family => pool_family, :quota => quota)
  deployment = Deployment.new(:name => deployment_name, :pool => pool, :owner => User.first)
  deployment.import_xml_from_url("http://localhost/deployables/deployable1.xml")
  deployment.save!
end

Then /^I should have a pool named "([^\"]*)"$/ do |name|
  Pool.find_by_name(name).should_not be_nil
end

When /^(?:|I )check "([^"]*)" pool$/ do |pool_name|
  pool = Pool.find_by_name(pool_name)
  check("pool_checkbox_#{pool.id}")
end

Then /^there should only be (\d+) pools$/ do |number|
  Pool.count.should == number.to_i
end

Then /^I should see the following:$/ do |table|
  table.raw.each do |array|
    array.each do |text|
      Then 'I should see "' + text + '"'
    end
  end
end

Given /^the "([^\"]*)" Pool has a quota with following capacities:$/ do |name,table|
  quota_hash = {}
  table.hashes.each do |hash|
    quota_hash[hash["resource"]] = hash["capacity"]
  end

  @pool = Pool.find_by_name(name)
  @quota = Factory(:quota, quota_hash)

  @pool.quota_id = @quota.id
  @pool.save
end

Given /^I renamed default_pool to pool_default$/ do
  p = Pool.find_by_name("default_pool")
  p.name = "pool_default"
  p.save
end

Then /^I should see (\d+) pools in JSON format$/ do |arg1|
  data = ActiveSupport::JSON.decode(response.body)
  data.length.should == arg1.to_i
end

When /^I am viewing the pool "([^"]*)"$/ do |arg1|
  visit pool_url(Pool.find_by_name(arg1))
end

Then /^I should see pool "([^"]*)" in JSON format$/ do |arg1|
  pool = Pool.find_by_name(arg1)
  data = ActiveSupport::JSON.decode(response.body)
  data['pool']['name'].should == pool.name
end

When /^I create a pool$/ do
  pool = Factory.build :pool
  pool.pool_family.save!
  visit pools_url, :post, 'pool[name]' => pool.name, 'pool[pool_family_id]' => pool.pool_family.id
end

Then /^I should get back a pool in JSON format$/ do
  data = ActiveSupport::JSON.decode(response.body)
  data['pool'].should_not be_nil
end

When /^I delete "([^"]*)" pool$/ do |arg1|
  visit(multi_destroy_pools_url, :post, 'pools_selected[]' => Pool.find_by_name(arg1).id)
end

Given /^there are (\d+) pools$/ do |arg1|
  Pool.all.each {|i| i.destroy}
  arg1.to_i.times do |i|
    Factory :pool, :name => "pool#{i}"
  end
end
