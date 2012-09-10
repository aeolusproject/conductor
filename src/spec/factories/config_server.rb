#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
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
    response = FakeResponse.new("200", "OK")
    cs.stub!(:test_connection).and_return(response) if cs.respond_to? :stub!
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
    response = FakeResponse.new("401", "Unauthroized")
    cs.stub!(:test_connection).and_return(response) if cs.respond_to? :stub!
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
