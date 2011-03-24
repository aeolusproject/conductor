Factory.define :provider_account do |f|
  f.sequence(:label) { |n| "test label#{n}" }
  f.association :provider
  f.association :quota
  f.after_build do |acc|
    acc.stub!(:generate_auth_key).and_return(nil) if acc.respond_to?(:stub!)
  end
end

Factory.define :mock_provider_account, :parent => :provider_account do |f|
  f.association :provider, :factory => :mock_provider
  f.after_build do |acc|
    acc.credentials << Factory.build(:username_credential)
    acc.credentials << Factory.build(:password_credential)
  end
end

Factory.define :ec2_provider_account, :parent => :provider_account do |f|
  f.association :provider, :factory => :ec2_provider
  f.after_build do |acc|
    acc.credentials << Factory.build(:ec2_username_credential)
    acc.credentials << Factory.build(:ec2_password_credential)
    acc.credentials << Factory.build(:ec2_account_id_credential)
    acc.credentials << Factory.build(:ec2_x509private_credential)
    acc.credentials << Factory.build(:ec2_x509public_credential)
  end

end
