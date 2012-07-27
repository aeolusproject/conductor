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

Rails.configuration.middleware.use RailsWarden::Manager do |config|
  config.failure_app = UserSessionsController
  config.default_scope = :user

  # all UI requests are handled in the default scope
  config.scope_defaults(
    :user,
    :strategies   => [SETTINGS_CONFIG[:auth][:strategy].to_sym],
    :store        => true,
    :action       => 'unauthenticated'
  )

  config.scope_defaults(
    :api,
    :strategies   => [SETTINGS_CONFIG[:auth][:strategy].to_sym],
    :store        => true,
    :action       => 'unauthenticated'
  )
end

class Warden::SessionSerializer
  def serialize(user)
    raise ArgumentError, "Cannot serialize invalid user object: #{user}" if not user.is_a? User and user.id.is_a? Integer
    user.id
  end

  def deserialize(id)
    raise ArgumentError, "Cannot deserialize non-integer id: #{id}" unless id.is_a? Integer
    User.find(id) rescue nil
  end
end

module Warden::Mixins::Common
  def get_credentials
    if request.authorization && request.authorization =~ /^Basic (.*)/m
      Rails.logger.debug("Using basic HTTP auth header")
      ActiveSupport::Base64.decode64($1).split(/:/, 2)
    else
      [params[:login], params[:password]]
    end
  end
end

# authenticate against database
Warden::Strategies.add(:database) do
  def authenticate!
    login, password = get_credentials
    return unless login && password
    Rails.logger.debug("Warden is authenticating #{login} against database")
    ipaddress = request.env[ 'HTTP_X_FORWARDED_FOR' ] ? request.env[ 'HTTP_X_FORWARDED_FOR' ] : request.remote_ip
    u = User.authenticate(login, password, ipaddress)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end


# authenticate against LDAP
Warden::Strategies.add(:ldap) do
  def authenticate!
    login, password = get_credentials
    return unless login && password
    Rails.logger.debug("Warden is authenticating #{login} against ldap")
    ipaddress = request.env[ 'HTTP_X_FORWARDED_FOR' ] ? request.env[ 'HTTP_X_FORWARDED_FOR' ] : request.remote_ip
    u = User.authenticate_using_ldap(login, password, ipaddress)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end
Warden::Manager.after_authentication do |user,auth,opts|
  SessionEntity.update_session(auth.request.session_options[:id], user)
end
