require 'vcr'

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/cassettes'
  c.stub_with :webmock
  # FIXME: This is necessary because the setup for each test will reset the database and
  # invoke db:seed, which triggers Solr to reindex the newly-created objects, which
  # is done over an HTTP request...
  c.allow_http_connections_when_no_cassette = true
end

# Mock all iwhd requests
Warehouse::Connection.class_eval do
  def do_request(path = '', opts={})
    opts[:method]  ||= :get
    opts[:content] ||= ''
    opts[:plain]   ||= false
    opts[:headers] ||= {}
    result=nil
    VCR.use_cassette('iwhd_connection', :record => :new_episodes) do
      result = RestClient::Request.execute :method => opts[:method], :url => @uri + path, :payload => opts[:content], :headers => opts[:headers]
    end

    return Nokogiri::XML result unless opts[:plain]
    return result
  end
end

# Mock request for deployable xml
Deployment.class_eval do
  def import_xml_from_url(url)
    # Right now we allow this to raise exceptions on timeout / errors
    result = nil
    response = nil
    VCR.use_cassette('deployable_xml', :record => :new_episodes) do
      resource = RestClient::Resource.new(url, :open_timeout => 10, :timeout => 45)
      response = resource.get
    end
    if response.code == 200
      self.deployable_xml = response
    else
      false
    end
  end
end
