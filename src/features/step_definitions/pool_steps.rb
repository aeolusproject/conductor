Given /^I am an authorised user$/ do
  @admin_permission = Factory :admin_permission
  @user = @admin_permission.user
end

Given /^I have Pool Creator permissions on a pool named "([^\"]*)"$/ do |name|
  @pool = Factory(:pool, :name => name)
  Factory(:pool_creator_permission, :user => @user, :permission_object => @pool)
end

Given /^there are no pools$/ do
  Pool.delete_all
end

Given /^there are (\d+) pools$/ do |number|
  Pool.count.should == number.to_i
end

Given /^there is not a pool named "([^\"]*)"$/ do |name|
  Pool.find_by_name(name).should be_nil
end

Given /^a pool "([^"]*)" exists$/ do |pool_name|
  pool_family = PoolFamily.find_by_name('default') || Factory(:pool_family)
  quota = Quota.first || Factory(:quota)
  Pool.create!(:name => pool_name, :pool_family => pool_family, :quota => quota)
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
