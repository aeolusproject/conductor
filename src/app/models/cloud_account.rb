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

class CloudAccount < ActiveRecord::Base
  belongs_to :provider
  has_many :portal_pools,  :dependent => :destroy

  # what form does the account quota take?

  # we aren't yet defining the local user object
  # has_many :portal_users


  validates_presence_of :provider_id

  validates_presence_of :username
  validates_uniqueness_of :username, :scope => :provider_id
  validates_presence_of :password

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  def connect
    begin
      return DeltaCloud.new(username, password, provider.url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def self.find_or_create(account)
    a = CloudAccount.find_by_username_and_provider_id(account["username"], account["provider_id"])
    return a.nil? ? CloudAccount.new(account) : a
  end
end
