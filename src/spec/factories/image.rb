# Should have an image factory, that specifies name, key and arch
# pool_image, and provider_image factories should extend image factory.

Factory.define :image do |i|
  i.sequence(:name) { |n| "image#{n}" }
  i.status 'queued'
  i.target 'ec2'
  i.association(:template)
end
