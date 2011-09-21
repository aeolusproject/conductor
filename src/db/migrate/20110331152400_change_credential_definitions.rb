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

class ChangeCredentialDefinitions < ActiveRecord::Migration
  def self.up
    transform_credential_definitions
  end

  def self.down
    transform_credential_definitions_back
  end

  def self.transform_credential_definitions
    ec2 = ProviderType.find_by_codename('ec2')
    CredentialDefinition.all.each do |cred|
      if cred.provider_type != ec2
        if cred.name == 'username'
          cred.update_attribute(:label, 'Username')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Password')
        end
      else
        if cred.name == 'username'
          cred.update_attribute(:label, 'API Key')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Secret')
        end
      end
    end
  end

  def self.transform_credential_definitions_back
    ec2 = ProviderType.find_by_codename('ec2')
    CredentialDefinition.all.each do |cred|
      if cred.provider_type != ec2
        if cred.name == 'username'
          cred.update_attribute(:label, 'API Key')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Secret')
        end
      else
        if cred.name == 'username'
          cred.update_attribute(:label, 'Username')
        elsif cred.name == 'password'
          cred.update_attribute(:label, 'Password')
        end
      end
    end
  end

end
