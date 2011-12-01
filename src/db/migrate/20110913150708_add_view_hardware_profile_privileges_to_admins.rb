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

class AddViewHardwareProfilePrivilegesToAdmins < ActiveRecord::Migration
  def self.up
    return if Role.all.empty?

    Role.transaction do
      ["HWP Administrator", "Administrator"].each do |role_name|
        role = Role.find_or_initialize_by_name(role_name)

        priv_type = HardwareProfile
        priv_action = 'view'
        Privilege.create!(:role => role, :target_type => 'HardwareProfile',
                          :action => 'view')
      end
    end
  end

  def self.down
  end
end
