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

  factory :provider_account do
    sequence(:label) { |n| "test label#{n}" }
    association :provider
    association :quota
  end

  factory :mock_provider_account, :parent => :provider_account do
    association :provider, :factory => :mock_provider
    after_build do |acc|
      acc.credentials << Factory.build(:username_credential)
      acc.credentials << Factory.build(:password_credential)
    end
  end

  factory :mock_provider_account2, :parent => :provider_account do
    association :provider, :factory => :mock_provider2
    after_build do |acc|
      acc.credentials << Factory.build(:username_credential)
      acc.credentials << Factory.build(:password_credential)
    end
  end

  factory :ec2_provider_account, :parent => :provider_account do
    association :provider, :factory => :ec2_provider
    after_build do |acc|
      acc.credentials << Factory.build(:ec2_username_credential)
      acc.credentials << Factory.build(:ec2_password_credential)
      acc.credentials << Factory.build(:ec2_account_id_credential)
      acc.credentials << Factory.build(:ec2_x509private_credential)
      acc.credentials << Factory.build(:ec2_x509public_credential)
    end

  end

  factory :disabled_provider_account, :parent => :mock_provider_account do
    association :provider, :factory => :disabled_provider
  end

end
