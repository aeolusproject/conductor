FactoryGirl.define do
  factory :image_version, :class => Tim::ImageVersion do
    association :base_image, :factory => :base_image_with_template
  end
end
