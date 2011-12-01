#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
Given /^the default quota is set to (\d+)$/ do |no_instances|
  @default_quota = MetadataObject.lookup("self_service_default_quota")
  @default_quota.maximum_running_instances = no_instances
  @default_quota.save
end

Then /^the default quota should be (\d+)$/ do |no_instances|
  @default_quota.reload
  @default_quota.maximum_running_instances.should == no_instances.to_i
end