# == Schema Information
#
# Table name: instance_keys
#
#  id          :integer         not null, primary key
#  instance_id :integer         not null
#  name        :string(255)     not null
#  pem         :text
#  created_at  :datetime
#  updated_at  :datetime
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

class InstanceKey < ActiveRecord::Base
  belongs_to :instance
  before_destroy :destroy_instance_key

  def destroy_instance_key
    begin
      instance.provider_account.connect.key(self.name).destroy!
    rescue
      Rails.logger.error "failed to destroy instance key #{self.name} of instance #{instance.name}: #{$!.message}"
    end
    true
  end
end
