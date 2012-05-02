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

  factory :provider do
    sequence(:name) { |n| "provider#{n}" }
    provider_type { Factory.build :provider_type }
    url { |p| "http://www." + p.name + ".com/api" }
  end

  factory :mock_provider, :parent => :provider do
    provider_type {ProviderType.find_by_deltacloud_driver("mock")}
    url 'http://localhost:3002/api'
    hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm1, :provider => p) << FactoryGirl.create(:realm2, :provider => p) }
  end

  factory :mock_provider2, :parent => :provider do
    name 'mock2'
    provider_type { ProviderType.find_by_deltacloud_driver("mock") }
    url 'http://localhost:3002/api'
    after_create { |p| p.realms << FactoryGirl.create(:realm3, :provider => p) }
  end

  factory :mock_provider_with_unavailable_realm, :parent => :provider do
    provider_type {ProviderType.find_by_deltacloud_driver("mock")}
    url 'http://localhost:3002/api'
    hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm1, :provider => p, :available => false) }
  end

  factory :ec2_provider, :parent => :provider do
    name 'amazon-ec2'
    provider_type { ProviderType.find_by_deltacloud_driver("ec2") }
    url 'http://localhost:3002/api'
    deltacloud_provider 'ec2-us-east-1'
    hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm4, :provider => p) }
  end

  factory :disabled_provider, :parent => :mock_provider do
    enabled false
  end

  factory :mock_provider_for_vcr_data, :parent => :mock_provider do
    name "mock"
    after_create { |p| p.provider_accounts << FactoryGirl.create(:mock_provider_account, :provider => p) }
  end

  factory :unavailable_mock_provider, :parent => :mock_provider do
    available false
  end
end
