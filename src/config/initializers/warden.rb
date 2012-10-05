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
      Base64.decode64($1).split(/:/, 2)
    else
      [params[:username], params[:password]]
    end
  end
end

# authenticate against database
Warden::Strategies.add(:database) do
  def authenticate!
    username, password = get_credentials
    return unless username && password
    Rails.logger.debug("Warden is authenticating #{username} against database")
    ipaddress = request.env[ 'HTTP_X_FORWARDED_FOR' ] ? request.env[ 'HTTP_X_FORWARDED_FOR' ] : request.remote_ip
    u = User.authenticate(username, password, ipaddress)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end


# authenticate against LDAP
Warden::Strategies.add(:ldap) do
  def authenticate!
    username, password = get_credentials
    return unless username && password
    Rails.logger.debug("Warden is authenticating #{username} against ldap")
    ipaddress = request.env[ 'HTTP_X_FORWARDED_FOR' ] ? request.env[ 'HTTP_X_FORWARDED_FOR' ] : request.remote_ip
    u = User.authenticate_using_ldap(username, password, ipaddress)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end

Warden::Strategies.add(:kerberos) do
  def authenticate!
    username = request.env[ 'HTTP_X_FORWARDED_USER' ]
    Rails.logger.debug("Warden is authenticating #{username} against kerberos")
    ipaddress = request.env[ 'HTTP_X_FORWARDED_FOR' ] ? request.env[ 'HTTP_X_FORWARDED_FOR' ] : request.remote_ip
    u = User.authenticate_using_krb(username, ipaddress)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end

Warden::Manager.after_authentication do |user,auth,opts|
  current_session_id = auth.request.session_options[:id]
  session = auth.env['rack.session']
  perm_session = PermissionSession.create!(:user => user,
                                           :session_id => current_session_id)
  session[:permission_session_id] = perm_session.id
  perm_session.update_session_entities(user)
end
Warden::Manager.after_set_user do |user,auth,opts|
  current_session_id = auth.request.session_options[:id]
  session = auth.env['rack.session']
  perm_session_id = session[:permission_session_id]
  if perm_session_id
    perm_session = PermissionSession.find(perm_session_id)
    #if session_id doesn't match what we originally set, update the value
    # This isn't needed for perm checks (that's why we store
    # permission_session_id), but matching the correct session_id will facilitate
    # permission_session cleanup
    if perm_session && (perm_session.session_id != current_session_id)
      perm_session.session_id = current_session_id
      perm_session.save!
    end
  end
end
