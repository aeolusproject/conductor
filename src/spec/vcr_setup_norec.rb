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

require 'vcr'
require 'tempfile'

# FIXME: vcr 1.10 doesn't allow effectively select which hosts+ports
# should be ignored => this moneky patch ignores all requests except
# warehouse connects
module VCR
  class Cassette
    def should_allow_http_connections?
      true
    end
  end
end

def merge_cassettes
  file = Tempfile.new(['vcr', '.yml'])
  file.puts '---'
  Dir.glob("#{::Rails.root.to_s}/spec/vcr/cassettes/*yml").each do |fname|
    data = File.readlines(fname)
    data.slice!(0) if data.first =~ /^---\s*$/
    file.puts data.join
  end
  file.close(false)
  file
end

# if we want to just run tests, we load one big cassette only once
puts "==== using VCR fast mode, set VCR_RECORD variable if you want to record new tests ==="
file = merge_cassettes
VCR.config do |c|
  c.cassette_library_dir = File.dirname(file.path)
  c.stub_with :webmock
  # FIXME: This is necessary because the setup for each test will reset the database and
  # invoke db:seed, which triggers Solr to reindex the newly-created objects, which
  # is done over an HTTP request...
  c.allow_http_connections_when_no_cassette = true
end

VCR::Cassette.new(File.basename(file.path, '.yml'), :record => :none, :match_requests_on => [:method, :uri, :body])
