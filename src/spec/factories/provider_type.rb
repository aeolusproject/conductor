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

  factory :provider_type do
    sequence(:name) { |n| "name#{n}" }
    sequence(:deltacloud_driver) { |n| "deltacloud_driver#{n}" }
  end

  factory :mock_provider_type, :parent => :provider_type do
    name 'Mock'
    deltacloud_driver 'mock'
  end

  factory :ec2_provider_type, :parent => :provider_type do
    name 'Amazon EC2'
    deltacloud_driver 'ec2'
  end

  factory :provider_type_with_credential_definitions, :parent => :provider_type do
    after_create do |provider_type|
      provider_type.credential_definitions << FactoryGirl.create(:text_credential_definition, :provider_type => provider_type)
      provider_type.credential_definitions << FactoryGirl.create(:password_credential_definition, :provider_type => provider_type)
    end
  end

end
