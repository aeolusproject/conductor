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
            Permission.create!(:entity => @user.entity, :role => default_role, :permission_object => default_obj)
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
