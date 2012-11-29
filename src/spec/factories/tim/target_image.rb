FactoryGirl.define do
  factory :target_image, :class => Tim::TargetImage do
    provider_type { ProviderType.find_by_deltacloud_driver('mock') }
    association :image_version
  end
end
