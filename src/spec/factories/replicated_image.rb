Factory.define :replicated_image do |ri|
  ri.association :image
  ri.association :provider
  ri.sequence(:provider_image_key) { |n| "provider_image_key#(n)" }
end