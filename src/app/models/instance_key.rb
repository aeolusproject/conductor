# == Schema Information
# Schema version: 20110207110131
#
# Table name: instance_keys
#
#  id                      :integer         not null, primary key
#  instance_key_owner_id   :integer         not null
#  instance_key_owner_type :string(255)     not null
#  name                    :string(255)     not null
#  pem                     :text
#  created_at              :datetime
#  updated_at              :datetime
#

 #
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#

require 'openssl'
require 'base64'

class InstanceKey < ActiveRecord::Base

  belongs_to :instance_key_owner, :polymorphic => true

  def replace_key(addr, old_pem)
    key = generate_ssh_key
    replace_on_server(addr, old_pem, key[:public])
    self.pem = key[:private]
  end

  private

  def replace_on_server(addr, old_pem, new_pub)
    provider_type = self.instance_key_owner.provider_account.provider.provider_type
    Net::SCP::start(addr, provider_type.ssh_user, :key_data => [old_pem], :keys => []) do |scp|
      scp.upload! StringIO.new(new_pub), File.join(provider_type.home_dir, '/.ssh/authorized_keys')
    end
  end

  def generate_ssh_key
    key = OpenSSL::PKey::RSA.generate(1024)
    writer = Net::SSH::Buffer.new
    writer.write_key key
    ssh_key = Base64.encode64( writer.to_s ).strip.gsub( /[\n\r\t ]/, "" )
    {
      :private => key.export,
      :public => "#{key.ssh_type} #{ssh_key} #{ENV['USER']}@#{ENV['HOSTNAME']}"
    }
  end
end
