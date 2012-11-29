FactoryGirl.define do
  factory :base_image, :class => Tim::BaseImage do
    name "baseimage"
    description "description of test image"
    #association :pool_family
    # make sure that template and image have same pool family
    pool_family { template ? template.pool_family : create(:pool_family)}
  end

  factory :base_image_with_template, :parent => :base_image do
    association :template, :factory => :template
  end
end
