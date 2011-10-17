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

class PermissionsController < ApplicationController
  before_filter :require_user
  before_filter :set_permissions_header

  def index
    set_permission_object(Privilege::PERM_VIEW)
    respond_to do |format|
      format.html
      format.json { render :json => @permission_object.as_json }
      format.js { render :partial => 'index' }
    end
  end

  def new
    set_permission_object
    @users = User.all
    @roles = Role.find_all_by_scope(@permission_object.class.name)
    load_headers
    load_users
    respond_to do |format|
      format.html
      format.js { render :partial => 'new' }
    end
  end

  def create
    set_permission_object
    added=[]
    not_added=[]
    params[:user_role_selected].each do |user_role|
      user_id,role_id = user_role.split(",")
      unless role_id.nil?
        permission = Permission.new(:user_id => user_id,
                                    :role_id => role_id,
                                    :permission_object => @permission_object)
        if permission.save
          added << permission.user.login + " " + permission.role.name
        else
          not_added << permission.user.login + " " + permission.role.name
        end
      end
    end
    unless added.empty?
      flash[:notice] = "#{t('permissions.flash.notice.added')}: #{added.join(', ')}"
    end
    unless not_added.empty?
      flash[:error] = "#{t('permissions.flash.error.not_added')}: #{not_added.join(', ')}"
    end
    if added.empty? and not_added.empty?
      flash[:error] = t "permissions.flash.error.no_users_selected"
    end
    respond_to do |format|
      format.html { redirect_to send("#{@path_prefix}polymorphic_path",
                                     @permission_object,
                                     :details_tab => :permissions,
                                     :only_tab => true) }
      format.js { render :partial => 'index',
                    :permission_object_type => @permission_object.class.name,
                    :permission_object_id => @permission_object.id }
    end
  end

  def multi_update
    set_permission_object
    modified=[]
    not_modified=[]
    params[:permission_role_selected].each do |permission_role|
      permission_id,role_id = permission_role.split(",")
      unless role_id.nil?
        permission = Permission.find(permission_id)
        role = Role.find(role_id)
        old_role = permission.role
        unless permission.role == role
          permission.role = role
          if permission.save
            modified << permission.user.login + " " + permission.role.name + " from " + old_role.name
          else
            not_modified << permission.user.login + " " + permission.role.name
          end
        end
      end
    end
    unless modified.empty?
      flash[:notice] = "#{t('permissions.flash.notice.modified')}: #{modified.join(', ')}"
    end
    unless not_modified.empty?
      flash[:error] = "#{t('permissions.flash.error.not_add')}: #{not_modified.join(', ')}"
    end
    if modified.empty? and not_modified.empty?
      flash[:error] = t"permissions.flash.error.no_users_selected"
    end
    respond_to do |format|
      format.html { redirect_to send("#{@path_prefix}polymorphic_path",
                                     @permission_object,
                                     :details_tab => :permissions,
                                     :only_tab => true) }
      format.js { render :partial => 'index',
                    :permission_object_type => @permission_object.class.name,
                    :permission_object_id => @permission_object.id }
    end
  end

  def multi_destroy
    set_permission_object
    deleted=[]
    not_deleted=[]

    Permission.find(params[:permission_selected]).each do |p|
      if check_privilege(Privilege::PERM_SET, p.permission_object) && p.destroy
        deleted << p.user.login + " " + p.role.name
      else
        not_deleted << p.user.login + " " + p.role.name
      end
    end

    unless deleted.empty?
      flash[:notice] = "#{t('permissions.flash.notice.deleted')}: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "#{t('permissions.flash.error.not_deleted')}: #{not_deleted.join(', ')}"
    end
    respond_to do |format|
      format.html { redirect_to send("#{@path_prefix}polymorphic_path",
                                     @permission_object,
                                     :details_tab => :permissions,
                                     :only_tab => true) }
        format.js { render :partial => 'index',
                    :permission_object_type => @permission_object.class.name,
                    :permission_object_id => @permission_object.id }
        format.json { render :json => @permission, :status => :created }
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

  def load_users
    sort_order = params[:sort_by].nil? ? "login" : params[:sort_by]
    @users = User.all(:order => sort_order)
  end

  def load_headers
    @header = [
      { :name => '', :sortable => false },
      { :name => t('users.index.username'), :sortable => false },
      { :name => t('users.index.last_name'), :sortable => false },
      { :name => t('users.index.first_name'), :sortable => false },
      { :name => t('role'), :sortable => false }
    ]
  end

  def set_permission_object (required_role=Privilege::PERM_SET)
    obj_type = params[:permission_object_type]
    id = params[:permission_object_id]
    @path_prefix = params[:path_prefix]
    @permission_object = obj_type.constantize.find(id) if obj_type and id
    raise RuntimeError, "invalid permission object" if @permission_object.nil?
    require_privilege(required_role, @permission_object)
  end
end
