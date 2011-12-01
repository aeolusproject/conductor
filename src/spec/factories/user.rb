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

  factory :user do |u|
    sequence(:login) { |n| "user#{n}" }
    password 'secret'
    password_confirmation 'secret'
    first_name 'John'
    last_name 'Smith'
    association :quota
    email "#{:login}@example.com"
    #after_build { |u| u.email ||= "#{u.login}@example.com" }
  end

  factory :email_user , :parent => :user do
    email = :email
  end

  factory :other_named_user, :parent => :user do
    first_name 'Jane'
    last_name 'Doe'
  end

  factory :tuser, :parent => :user do
    last_login_ip '192.168.1.1'
  end

  factory :admin_user, :parent => :user do
    login 'admin'
  end

  factory :pool_creator_user, :parent => :user do
  end

  factory :provider_admin_user, :parent => :user do
  end

  factory :pool_user, :parent => :user do
    sequence(:login) { |n| "pool_user#{n}" }
  end

  factory :pool_user2, :parent => :user do
    sequence(:login) { |n| "pool_user2#{n}" }
  end

end
