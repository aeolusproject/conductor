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

require 'ldap_fluff'

module Ldap
  def self.valid_ldap_authentication?(uid, password)
    ldap = LdapFluff.new
    ldap.authenticate? uid, password
  end

  def self.ldap_groups(uid)
    ldap = LdapFluff.new
    ldap.group_list(uid)
  end

  def self.is_in_groups(uid, grouplist)
    ldap = LdapFluff.new
    ldap.is_in_groups?(uid, grouplist)
  end
end
