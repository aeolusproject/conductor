Factory.define :push_job do |p|
  p.provider_image_id { Factory.create(:provider_image, :provider => Factory.create(:mock_provider_account).provider).id }
end
