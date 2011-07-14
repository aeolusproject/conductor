Factory.define :config_server do |f|
  f.sequence(:host) {|n| "config_server#{n}" }
end

Factory.define :base_config_server, :parent => :config_server do |f|
  f.host "localhost"
  f.port "80"
  f.username "username"
  f.password "password"
end

Factory.define :mock_config_server, :parent => :base_config_server do |f|
  f.association :provider_account, :factory => :mock_provider_account
  f.after_build do |cs|
    cs.stub!(:test_connection).and_return(nil) if cs.respond_to? :stub!
  end
end

Factory.define :invalid_credentials_config_server, :parent => :base_config_server, :default_strategy => :build do |f|
  f.port "443"
  f.username "bad_username"
  f.password "bad_password"
  f.certificate "cert"
  f.after_build do |cs|
    cs.stub!(:test_connection).and_raise(RestClient::Unauthorized) if cs.respond_to? :stub!
  end
end

Factory.define :invalid_host_or_port_config_server, :parent => :base_config_server, :default_strategy => :build do |f|
  f.host "bad_host"
  f.port "443"
  f.certificate "cert"
  f.after_build do |cs|
    cs.stub!(:test_connection).and_raise(Errno::ETIMEDOUT) if cs.respond_to? :stub!
  end
end
