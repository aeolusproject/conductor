Factory.define :cloud_account do |f|
  f.sequence(:username) { |n| "testUser#(n)" }
  f.password "testPassword"
  f.association :provider
end

Factory.define :mock_cloud_account, :parent => :cloud_account do |f|
  f.sequence(:username) { |n| "testMockUser#(n)" }
  f.password "testMockPassword"
  f.provider { |p| p.association(:mock_provider) }
end
