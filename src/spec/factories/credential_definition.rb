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
  factory :credential_definition do
    sequence(:name) { |n| "field#{n}" }
    sequence(:label) { |n| "field#{n}" }
    input_type 'text'
    association :provider_type
  end

  factory :text_credential_definition, :parent => :credential_definition do
    input_type 'text'
  end

  factory :password_credential_definition, :parent => :credential_definition do
    input_type 'password'
  end
end
