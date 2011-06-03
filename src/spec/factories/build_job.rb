Factory.define :build_job do |p|
  hydra = Typhoeus::Hydra.new
  response = Typhoeus::Response.new(:code => 200, :headers => "", :body => "<?xml version=\"1.0\" encoding=\"UTF-8\"><image><uuid>build-job-stub-uuid</uuid></image>", :time => 0.1)
  hydra.stub(:post, YAML.load_file("#{RAILS_ROOT}/config/image_factory_console.yml")['buildurl']).and_return(response)
  p.image_id { Factory.create(:legacy_image).id }
  p.hydra hydra
end
