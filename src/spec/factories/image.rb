# Should have an image factory, that specifies name, key and arch
# pool_image, and provider_image factories should extend image factory.

Factory.define :image do |i|
  i.sequence(:name) { |n| "image#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.architecture 'i686'
  i.provider { |p| Provider.new }
end

Factory.define :front_end_image, :parent => :image do |i|
  i.provider nil
end
