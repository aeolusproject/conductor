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

Conductor::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  #Mailer configuration
  config.action_mailer.delivery_method = SETTINGS_CONFIG[:action_mailer][:delivery_method].to_sym
  if SETTINGS_CONFIG[:smtp_settings] == :smtp
    config.action_mailer.smtp_settings = SETTINGS_CONFIG[:action_mailer][:smtp_settings]
  end

  ActionMailer::Base.default :from => SETTINGS_CONFIG[:action_mailer][:default_from]
  config.action_mailer.perform_deliveries = true
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {
    :protocol => SETTINGS_CONFIG[:action_mailer][:default_url_options][:protocol],
    :host => SETTINGS_CONFIG[:action_mailer][:default_url_options][:host]
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Otherwise we eat these connections even outside of tests:
  WebMock.allow_net_connect! if defined?(WebMock)

end
