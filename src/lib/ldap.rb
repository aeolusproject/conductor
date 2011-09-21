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

require 'net/ldap'

module Ldap
  def self.valid_ldap_authentication?(uid, password, ldap_config)
    ldap = LdapConnection.new(ldap_config)
    ldap.bind? uid, password
  end

  class LdapConnection
    attr_reader :ldap, :host, :base

    def initialize(config)
      @ldap = Net::LDAP.new
      @ldap.host = config['host']
      @base = config['base']
    end

    def bind?(uid, password)
      begin
        @ldap.auth "uid=#{uid},#{@base}", password
        @ldap.bind
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n  ")
        false
      end
    end
  end
end
