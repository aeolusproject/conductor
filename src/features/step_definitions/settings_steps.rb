Given /^the default quota is set to (\d+)$/ do |no_instances|
  @default_quota = MetadataObject.lookup("self_service_default_quota")
  @default_quota.maximum_running_instances = no_instances
  @default_quota.save
end

Then /^the default quota should be (\d+)$/ do |no_instances|
  @default_quota.reload
  @default_quota.maximum_running_instances.should == no_instances.to_i
end