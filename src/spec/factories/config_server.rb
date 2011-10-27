Factory.define :config_server do |f|
  f.sequence(:endpoint) {|n| "config_server#{n}" }
end

Factory.define :base_config_server, :parent => :config_server do |f|
  f.endpoint "https://localhost"
  f.key "key0123456789"
  f.secret "secret0123456789abcdefg"
end

Factory.define :mock_config_server, :parent => :base_config_server do |f|
  f.association :provider_account, :factory => :mock_provider_account
  f.after_build do |cs|
    cs.stub!(:test_connection).and_return(nil) if cs.respond_to? :stub!
  end
end

Factory.define :invalid_credentials_config_server, :parent => :base_config_server do |f|
  f.endpoint "https://localhost"
  f.key "bad_key"
  f.secret "bad_secret"
  f.to_create do |cs|
    # the default_strategy initialization parameter seemed much better
  end
  f.after_build do |cs|
    cs.stub!(:test_connection).and_raise(RestClient::Unauthorized) if cs.respond_to? :stub!
  end
end

Factory.define :invalid_endpoint_config_server, :parent => :base_config_server do |f|
  f.endpoint "https://bad_host"
  f.key "bad_key"
  f.secret "bad_secret"

  f.to_create do |cs|
    # the default_strategy initialization parameter seemed much better
  end
  f.after_build do |cs|
    cs.stub!(:test_connection).and_raise(Errno::ETIMEDOUT) if cs.respond_to? :stub!
  end
end
