Factory.define :user do |u|
  u.login 'myuser'
  u.email 'myuser@example.com'
  u.password 'secret'
  u.password_confirmation 'secret'
  #u.first_name 'John'
  #u.last_name 'Smith'
end

Factory.define :tuser, :parent => :user do |u|
  u.login 'tuser'
  u.email 'tuser@example.com'
end

Factory.define :admin_user, :parent => :user do |u|
  u.login 'padmin'
  u.email 'padmin@foobar.com'
end

Factory.define :provider_admin_user, :parent => :user do |u|
  u.login 'provider_admin'
  u.email 'provider_admin@foobar.com'
end
