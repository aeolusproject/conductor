FactoryGirl.define do
  factory :provider_image, :class => Tim::ProviderImage do
    association :target_image
    association :provider_account, :factory => :mock_provider_account
  end
end
