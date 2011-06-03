Factory.define :push_job do |p|
  p.legacy_provider_image_id { Factory.create(:legacy_provider_image, :provider => Factory.create(:mock_provider_account).provider).id }
end
