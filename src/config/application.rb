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

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if ENV['USE_BUNDLER'] == 'yes'
  puts "===== application.rb will try and use bundler ========="
  Bundler.require(:default, Rails.env) if defined?(Bundler)
else
  puts 'Using gem require instead of bundler'
  require 'rails_warden'
  require 'net/ldap'
  require 'deltacloud'
  require 'sass'
  require 'haml'
  require 'will_paginate'
  require 'nokogiri'
  require 'simple-navigation'
  require 'rest-client'
  require 'rack-restful_submit'
  require 'uuidtools'
  require 'pg'
  require 'thin'
  require 'json'
  require 'fastercsv'
  #require 'railties'

  if (ENV["RAILS_ENV"] == "cucumber" || ENV["RAILS_ENV"] == "test")
    puts "========= cucumber/test env deps loaded... =========="
    require 'rspec-rails'
    require 'factory_girl_rails'
    require 'timecop'
    require 'capybara'
    require 'cucumber'
    require 'database_cleaner'
    require 'vcr'
    require 'webmock'
    require 'launchy'
  end
end

$: << File.join(File.dirname(__FILE__), "../app")

module Conductor
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :instance_observer, :task_observer, :provider_account_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
    require File.dirname(__FILE__) + '/../lib/warehouse_model'

    config.after_initialize do
      Haml::Template.options[:format] = :html5
    end

    config.middleware.use Rack::RestfulSubmit
    ActiveRecord::Base.include_root_in_json = false
  end
end
