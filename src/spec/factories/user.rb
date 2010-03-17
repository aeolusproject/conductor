Factory.define :user do |u|
  u.sequence(:login) { |n| "user#{n}" }
  u.email { |e| "#{e.login}@example.host" }
  u.password 'secret'
  u.password_confirmation 'secret'
  u.first_name 'John'
  u.last_name 'Smith'
end

Factory.define :tuser, :parent => :user do |u|
end

Factory.define :admin_user, :parent => :user do |u|
end

Factory.define :provider_admin_user, :parent => :user do |u|
end
