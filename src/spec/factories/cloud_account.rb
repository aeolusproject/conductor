Factory.define :cloud_account do |f|
  f.sequence(:username) { |n| "testUser#{n}" }
  f.password "testPassword"
  f.sequence(:label) { |n| "test label#{n}" }
  f.account_number "3141"
  f.x509_cert_priv "x509 private key"
  f.x509_cert_pub "x509 public key"
  f.association :provider
end

Factory.define :mock_cloud_account, :parent => :cloud_account do |f|
  f.username "mockuser"
  f.password "mockpassword"
  f.provider { |p| p.association(:mock_provider) }
end

Factory.define :ec2_cloud_account, :parent => :cloud_account do |f|
  f.username "mockuser"
  f.password "mockpassword"
  f.provider { |p| p.association(:ec2_provider) }
end
