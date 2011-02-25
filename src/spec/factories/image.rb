# Should have an image factory, that specifies name, key and arch
# pool_image, and provider_image factories should extend image factory.

Factory.define :image do |i|
  i.sequence(:name) { |n| "image#{n}" }
  i.status 'queued'
  i.provider_type_id { ProviderType.find_by_codename("ec2").id }
  i.association(:template)
  i.after_build do |img|
    if img.respond_to?(:stub!)
      img.stub!(:build).and_return(true)
      img.stub!(:upload).and_return(true)
    end
  end
end
