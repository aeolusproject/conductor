Factory.define :push_job do |p|
  hydra = Typhoeus::Hydra.new
  response = Typhoeus::Response.new(:code => 200, :headers => "", :body => "<?xml version=\"1.0\" encoding=\"UTF-8\"><image><uuid>push-job-stub-uuid</uuid></image>", :time => 0.1)
  hydra.stub(:post, YAML.load_file("#{RAILS_ROOT}/config/image_factory_console.yml")['pushurl']).and_return(response)
  p.provider_image_id { Factory.create(:provider_image, :provider => Factory.create(:mock_provider_account).provider).id }
  p.hydra hydra
end
