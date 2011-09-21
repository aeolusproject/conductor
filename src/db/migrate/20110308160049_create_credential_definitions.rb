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

class CreateCredentialDefinitions < ActiveRecord::Migration
  def self.up
    create_table :credential_definitions do |t|
      t.string :name
      t.string :label
      t.string :input_type
      t.integer :provider_type_id

      t.timestamps
    end
    initialize_table
  end

  def self.down
    drop_table :credential_definitions
  end

  def self.initialize_table
    if CredentialDefinition.all.empty?
      ProviderType.all.each do |provider_type|
        unless provider_type.codename == 'ec2'
          CredentialDefinition.create!(:name => 'username', :label => 'API Key', :input_type => 'text', :provider_type_id => provider_type.id)
          CredentialDefinition.create!(:name => 'password', :label => 'Secret', :input_type => 'password', :provider_type_id => provider_type.id)
        else
          #for ec2 provider type
          CredentialDefinition.create!(:name => 'username', :label => 'Username', :input_type => 'text', :provider_type_id => provider_type.id)
          CredentialDefinition.create!(:name => 'password', :label => 'Password', :input_type => 'password', :provider_type_id => provider_type.id)
          CredentialDefinition.create!(:name => 'account_id', :label => 'AWS Account ID', :input_type => 'text', :provider_type_id => provider_type.id)
          CredentialDefinition.create!(:name => 'x509private', :label => 'EC2 x509 private key', :input_type => 'file', :provider_type_id => provider_type.id)
          CredentialDefinition.create!(:name => 'x509public', :label => 'EC2 x509 public key', :input_type => 'file', :provider_type_id => provider_type.id)
        end
      end
    end
  end
end
