#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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

VCR::Cassette.new(File.basename(file.path, '.yml'), :record => :none)
