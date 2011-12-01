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
  factory :view_state do
    sequence(:name) { |n| "view-state#{n}" }
    controller 'pools'
    action 'view'
    state("sort-column" => "name", "sort-order" => "desc", "columns" => ["name", "deployments", "instances"])
    association :user
  end
end
