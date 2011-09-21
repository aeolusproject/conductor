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

class ChangeCredentialDefinitionsNames < ActiveRecord::Migration
  def self.up
    CredentialDefinition.all.each do |cred|
      if name_mapping.has_key? cred.label
        cred.label = name_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.down
    reverse_mapping = name_mapping.invert
    CredentialDefinition.all.each do |cred|
      if reverse_mapping.has_key? cred.label
        cred.label = reverse_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.name_mapping
    {
      "API Key" => "Access Key",
      "Secret" => "Secret Access Key",
      "AWS Account ID" => "Account Number",
      "EC2 x509 private key" => "Key",
      "EC2 x509 public key" => "Certificate",
    }
  end
end
