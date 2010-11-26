Factory.define :replicated_image do |ri|
  ri.association :image
  ri.association :provider
  ri.sequence(:provider_image_key) { |n| "provider_image_key#(n)" }
  ri.uploaded true
  ri.registered true
end

Factory.define :mock_replicated_image, :parent => :replicated_image do |i|
  i.provider { |p| p.association(:mock_provider) }
end
