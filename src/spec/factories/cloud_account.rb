Factory.define :cloud_account do |f|
  f.sequence(:username) { |n| "testUser#(n)" }
  f.password "testPassword"
  f.association :provider
end