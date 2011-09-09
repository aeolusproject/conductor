# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'timecop'
require 'vcr_setup'

module RequestContentTypeHelper
  def accept_json
    @request.env["HTTP_ACCEPT"] = "application/json"
  end

  def accept_xml
    @request.env["HTTP_ACCEPT"] = "application/xml"
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

  config.before(:each, :type => :controller) do
    #activate_authlogic
  end

  config.after(:each, :type => :controller) do
    #current_user_session.destroy
  end
end
