FactoryGirl.define do

  factory :provider_account do
    sequence(:label) { |n| "test label#{n}" }
    association :provider
    association :quota
  end

  factory :mock_provider_account, :parent => :provider_account do
    association :provider, :factory => :mock_provider
    after_build do |acc|
      acc.credentials << Factory.build(:username_credential)
      acc.credentials << Factory.build(:password_credential)
    end
  end

  factory :ec2_provider_account, :parent => :provider_account do
    association :provider, :factory => :ec2_provider
    after_build do |acc|
      acc.credentials << Factory.build(:ec2_username_credential)
      acc.credentials << Factory.build(:ec2_password_credential)
      acc.credentials << Factory.build(:ec2_account_id_credential)
      acc.credentials << Factory.build(:ec2_x509private_credential)
      acc.credentials << Factory.build(:ec2_x509public_credential)
    end

  end

  factory :disabled_provider_account, :parent => :mock_provider_account do
    association :provider, :factory => :disabled_provider
  end

end
