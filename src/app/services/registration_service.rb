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

class RegistrationService
  attr_reader :error

  def initialize(user)
    @user = user
  end

  def save
    User.transaction do
      begin
        if @user.quota.nil?
          self_service_default_quota = MetadataObject.lookup("self_service_default_quota")
          @user.quota = Quota.new(
            :maximum_running_instances => self_service_default_quota.maximum_running_instances,
            :maximum_total_instances => self_service_default_quota.maximum_total_instances)
        end

        @user.save!
        # perm list in the format:
        #   "[resource1_key, resource1_role], [resource2_key, resource2_role], ..."
        MetadataObject.lookup("self_service_perms_list").split(/[\]],? ?|[\[]/).
          select {|x| !x.empty? }.each do |x|
            obj_key, role_key = x.split(/, ?/)
            default_obj = MetadataObject.lookup(obj_key)
            default_role = MetadataObject.lookup(role_key)
            Permission.create!(:user => @user, :role => default_role, :permission_object => default_obj)
          end
        return true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n  ")
        @error = e.message
        raise ActiveRecord::Rollback
      end
    end
    return false
  end

  def valid?
    @user.valid?
  end
end
