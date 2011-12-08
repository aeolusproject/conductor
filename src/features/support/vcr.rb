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
# Pull in our VCR configuration
if ENV['VCR_RECORD']
  require File.expand_path(File.dirname(__FILE__) + '../../../spec/vcr_setup.rb')
else
  require File.expand_path(File.dirname(__FILE__) + '../../../spec/vcr_setup_norec.rb')
end

def use_casette(casette)
  path = "#{::Rails.root.to_s}/spec/vcr/cassettes/features/#{casette}.yml"
  VCR.config do |c|
    c.cassette_library_dir = File.dirname(path)
    c.stub_with :webmock
    c.allow_http_connections_when_no_cassette = true
  end

  VCR::Cassette.new(File.basename(path, '.yml'), :record => :none)
end
