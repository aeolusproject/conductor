Factory.define :user do |u|
  u.sequence(:login) { |n| "user#{n}" }
  u.email { |e| "#{e.login}@example.host" }
  u.password 'secret'
  u.password_confirmation 'secret'
  u.first_name 'John'
  u.last_name 'Smith'
  u.association :quota
end

Factory.define :other_named_user, :parent => :user do |u|
  u.first_name 'Jane'
  u.last_name 'Doe'
end

Factory.define :tuser, :parent => :user do |u|
end

Factory.define :admin_user, :parent => :user do |u|
end

Factory.define :pool_creator_user, :parent => :user do |u|
end

Factory.define :provider_admin_user, :parent => :user do |u|
end

Factory.define :pool_user, :parent => :user do |u|
  u.sequence(:login) { |n| "pool_user#{n}" }
  u.email { |e| "#{e.login}@example.com" }
end

Factory.define :pool_user2, :parent => :user do |u|
  u.sequence(:login) { |n| "pool_user2#{n}" }
  u.email { |e| "#{e.login}@example.com" }
end
