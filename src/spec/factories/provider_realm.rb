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

  factory :provider_realm do
    sequence(:name) { |n| "provider_realm#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association(:provider)
  end

  factory :provider_realm1, :parent => :provider_realm do
  end

  factory :provider_realm2, :parent => :provider_realm do
  end

  factory :provider_realm3, :parent => :provider_realm do
  end

  factory :provider_realm4, :parent => :provider_realm do
  end

  factory :backend_realm, :parent => :provider_realm do
    name 'backend_name'
    external_key 'backend_key'
  end
end
