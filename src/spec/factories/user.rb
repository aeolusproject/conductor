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
