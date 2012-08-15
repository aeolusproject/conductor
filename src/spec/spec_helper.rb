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

Dir[File.dirname(__FILE__) + '/support/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/matchers/*.rb'].each {|file| require file }

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
  @session_id = 'ee73441902cb9445483e498cb05dc398'
  request.session_options[:id] = @session_id
  @session = ActiveRecord::SessionStore::Session.find_by_session_id(@session_id)
  @session = FactoryGirl.create :session unless @session
  SessionEntity.update_session(@session_id, user) if user
end

# Without these here, controller specs fail.  These 2 class_evals can
# be removed once stubs work and/or are added to the right place.
Provider.class_eval do
  def valid_framework?
    true
  end

  def valid_provider?
    true
  end
end

ProviderAccount.class_eval do

  def connect
    nil
  end

#  def valid_credentials?
#    true
#  end
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

  config.include Warden::Test::Helpers, :type => :request
  config.after(:each, :type => :request) do
    Warden.test_reset!
  end

end
