FactoryGirl.define do

  factory :user do |u|
    sequence(:login) { |n| "user#{n}" }
    password 'secret'
    password_confirmation 'secret'
    first_name 'John'
    last_name 'Smith'
    association :quota
    after_build { |u| u.email ||= "#{u.login}@example.com" }
  end

  factory :other_named_user, :parent => :user do
    first_name 'Jane'
    last_name 'Doe'
  end

  factory :tuser, :parent => :user do
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
