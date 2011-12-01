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

FactoryGirl.define do

  factory :quota do
    maximum_running_instances 10
    maximum_total_instances 15
  end

  factory :full_quota, :parent => :quota do
    running_instances 10
    total_instances 15
  end

  factory :unlimited_quota, :parent => :quota do
    maximum_running_instances nil
    maximum_total_instances nil
  end

end
