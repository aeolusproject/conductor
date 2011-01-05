Given /^I am an authorised user$/ do
  @admin_permission = Factory :admin_permission
  @user = @admin_permission.user
end

Given /^I have Pool Creator permissions on a pool named "([^\"]*)"$/ do |name|
  @pool = Factory(:pool, :name => name)
  Factory(:pool_creator_permission, :user => @user, :permission_object => @pool)
end

Given /^there is not a pool named "([^\"]*)"$/ do |name|
  Pool.find_by_name(name).should be_nil
end

Then /^I should have a pool named "([^\"]*)"$/ do |name|
  Pool.find_by_name(name).should_not be_nil
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
