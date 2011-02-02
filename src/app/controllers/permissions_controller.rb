#
# Copyright (C) 2010 Red Hat, Inc.
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

class PermissionsController < ApplicationController
  before_filter :require_user

  def show
    @permission = Permission.find(params[:id])
    require_privilege(Privilege::PERM_VIEW, @permission.permission_object)
  end

  def list
    set_permission_object Privilege::PERM_VIEW
  end

  def new
    set_permission_object Privilege::PERM_SET
    @permission = Permission.new(:permission_object_type => @permission_object.class,
                                 :permission_object_id => @permission_object.id)
    @users = User.all
    @roles = Role.find_all_by_scope(@permission_object.class.name)
  end

  def create
    @permission = Permission.new(params[:permission])
    require_privilege(Privilege::PERM_SET, @permission.permission_object)
    if request.post? && @permission.save
      flash[:notice] = "Permission record added."
      redirect_to :action => "list",
                  :permission_object_type => @permission.permission_object_type,
                  :permission_object_id => @permission.permission_object_id
    else
      @permission_object = @permission.permission_object
      @users = User.all
      @roles = Role.find_all_by_scope(@permission_object.class.name)
      render :action => 'new'
    end
  end

  def destroy
    if request.post?
      p =Permission.find(params[:permission][:id])
      require_privilege(Privilege::PERM_SET, p.permission_object)
      p.destroy
    end
    redirect_to :action => "list",
                :permission_object_type => p.permission_object_type,
                :permission_object_id => p.permission_object_id
  end

  private

  def set_permission_object(action)
    if !params[:permission_object_type].nil?
      @permission_object =
        params[:permission_object_type].constantize.find(params[:permission_object_id])
    elsif !params[:pool_id].nil?
      @permission_object = Pool.find params[:pool_id]
    elsif !params[:provider_id].nil?
      @permission_object = Provider.find params[:provider_id]
    elsif !params[:cloud_account_id].nil?
      @permission_object = ProviderAccount.find params[:cloud_account_id]
    elsif !params[:base_permission_object_id].nil?
      @permission_object = BasePermissionObject.find params[:base_permission_object_id]
    else
      @permission_object = BasePermissionObject.general_permission_scope
    end

    raise ActiveRecord::RecordNotFound if @permission_object.nil?

    require_privilege(action, @permission_object)
  end

end
