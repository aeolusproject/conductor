#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

class AddTemplateCreatorRole < ActiveRecord::Migration


  def self.up
    unless Role.all.empty?
      Role.transaction do
        role_name = "Template Creator"
        role = Role.find_or_initialize_by_name(role_name)
        role.update_attributes({:name => role_name, :scope => BasePermissionObject.name,
                                 :assign_to_owner => false})
        role.save!
        ["view","use","create"].each do |action|
          Privilege.create!(:role => role, :target_type => Template.name,
                            :action => action)
        end
      end
      settings = {"self_service_default_template_obj" => BasePermissionObject.general_permission_scope,
        "self_service_default_template_role" => Role.find_by_name("Template Creator"),
        "self_service_perms_list" => "[self_service_default_pool,self_service_default_role], [self_service_default_template_obj,self_service_default_template_role]"}
      settings.each_pair do |key, value|
        MetadataObject.set(key, value)
      end
    end
  end

  def self.down
  end
end
