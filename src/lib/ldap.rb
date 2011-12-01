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
      @ldap.host = config[:host]
      @ldap.port = config[:port] || 389
      @username_dn = config[:username_dn]
    end

    def bind?(uid, password)
      begin
        @ldap.auth(@username_dn % uid, password)
        @ldap.bind
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n  ")
        false
      end
    end
  end
end
