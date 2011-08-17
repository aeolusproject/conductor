# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'authlogic/test_case'
require 'timecop'
require 'vcr_setup'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  include Authlogic::TestCase
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