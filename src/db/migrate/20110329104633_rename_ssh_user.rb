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

class RenameSshUser < ActiveRecord::Migration
  def self.up
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    if pt
      pt.ssh_user = 'root'
      pt.home_dir = '/root'
      pt.save!
    end
  end

  def self.down
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    if pt
      pt.ssh_user = 'ec2-user'
      pt.home_dir = '/home/ec2-user'
      pt.save!
    end
  end
end
