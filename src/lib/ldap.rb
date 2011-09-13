#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

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
