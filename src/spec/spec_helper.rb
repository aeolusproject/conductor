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

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'timecop'

if ENV['VCR_RECORD']
  require 'vcr_setup'
else
  require 'vcr_setup_norec'
end

module RequestContentTypeHelper
  def accept_all
    @request.env["HTTP_ACCEPT"] = "*/*"
  end

  def accept_json
    @request.env["HTTP_ACCEPT"] = "application/json"
  end

  def accept_xml
    @request.env["HTTP_ACCEPT"] = "application/xml"
  end

  def send_and_accept_xml
    @request.env["HTTP_ACCEPT"] = "application/xml"
    @request.env["CONTENT_TYPE"] = "application/xml"
  end

end

include RequestContentTypeHelper
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

def mock_warden(user)
  request.env['warden'] = mock(Warden, :authenticate => user,
                                       :authenticate! => user,
                                       :user => user,
                                       :raw_session => nil)
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = Rails.root.join("spec/fixtures")

  #
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  config.mock_with :rspec
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner

  #config.before(:each, :type => :controller) do
  #  activate_authlogic
  #end

  #config.after(:each, :type => :controller) do
  #  current_user_session.destroy
  #end
end
