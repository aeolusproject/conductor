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

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if  File.exist?(File.expand_path('../../Gemfile.in', __FILE__))
  require File.join(File.dirname(__FILE__), '..', 'lib', 'aeolus', 'ext')
  puts 'Using gem require instead of bundler'
  Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__),:default, Rails.env)
else
  ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
  puts "===== application.rb will try and use bundler ========="
  Bundler.require(:default, Rails.env) if defined?(Bundler)
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
    config.active_record.observers = :instance_observer, :task_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'overrides','**', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    require File.dirname(__FILE__) + '/../lib/exceptions'
    require File.dirname(__FILE__) + '/../lib/image'

    # Read settings config (accessible at Conductor::Application::SETTINGS_CONFIG)
    ::SETTINGS_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    #field_with_errors should be span instead of div
    config.action_view.field_error_proc = Proc.new do |html_tag, instance|
      "<span class=\"field_with_errors\">#{html_tag}</span>".html_safe
    end

    config.after_initialize do
      Haml::Template.options[:format] = :html5
    end

    #config.middleware.swap Rack::MethodOverride, Rack::RestfulSubmit
    config.middleware.insert_before(Rack::MethodOverride, Rack::RestfulSubmit)
    ActiveRecord::Base.include_root_in_json = false
  end
end
