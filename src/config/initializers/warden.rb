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
    :store        => false,
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
    u = User.authenticate(login, password)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end


# authenticate against LDAP
Warden::Strategies.add(:ldap) do
  def authenticate!
    login, password = get_credentials
    return unless login && password
    Rails.logger.debug("Warden is authenticating #{login} against ldap")
    u = User.authenticate_using_ldap(login, password)
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end
