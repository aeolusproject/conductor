#
#   Copyright 2012 Red Hat, Inc.
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

Given /^there is a provider priority group named "([^"]*)" for pool "([^"]*)"$/ do |priority_group_name, pool_name|
  @pool = Pool.find_by_name(pool_name)
  @priority_group = FactoryGirl.create(:provider_priority_group, :pool => @pool, :name => priority_group_name)
end