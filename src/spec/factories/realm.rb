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

  factory :realm do
    sequence(:name) { |n| "realm#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association(:provider)
  end

  factory :realm1, :parent => :realm do
  end

  factory :realm2, :parent => :realm do
  end

  factory :realm3, :parent => :realm do
  end

  factory :realm4, :parent => :realm do
  end

  factory :backend_realm, :parent => :realm do
    name 'backend_name'
    external_key 'backend_key'
  end
end
