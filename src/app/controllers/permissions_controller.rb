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

class PermissionsController < ApplicationController
  before_filter :require_user

  def index
    set_permission_object(Privilege::PERM_VIEW)
    @roles = Role.find_all_by_scope(@permission_object.class.name)
    respond_to do |format|
      format.html
      format.json { render :json => @permission_object.as_json }
      format.js { render :partial => 'permissions' }
    end
  end

  def new
    set_permission_object
    @title = _("Grant Access")
    @users = User.all
    @roles = Role.find_all_by_scope(@permission_object.class.name)
    if @permission_object == BasePermissionObject.general_permission_scope
      @return_text = _("Global Role Grants")
      @summary_text =  _("Choose global role assignments for users")
    else
      @return_text =  "#{@permission_object.name} " + @permission_object.class.model_name.human
      @summary_text = _("Choose roles for users you would like to grant access to this") + " " + @permission_object.class.model_name.human
    end
    load_headers
    load_entities
    respond_to do |format|
      format.html
      format.js { render :partial => 'new' }
    end
  end

  def create
    set_permission_object
    added=[]
    not_added=[]
    params[:entity_role_selected].each do |entity_role|
      entity_id,role_id = entity_role.split(",")
      unless role_id.nil?
        permission = Permission.new(:entity_id => entity_id,
                                    :role_id => role_id,
                                    :permission_object => @permission_object)
        if permission.save
          added << t('permissions.flash.fragment.user_and_role', :user => permission.entity.name,
                      :role => t(permission.role.name, :scope=> :role_defs, :default => permission.role.name))
        else
          not_added << t('permissions.flash.fragment.user_and_role', :user => permission.entity.name,
                          :role => t(permission.role.name, :scope=> :role_defs, :default => permission.role.name) )
        end
      end
    end
    unless added.empty?
      flash[:notice] = _("Added the following User Roles: %s") % added.to_sentence
    end
    unless not_added.empty?
      flash[:error] = _("Could not add these User Roles: %s") % not_added.to_sentence
    end
    if added.empty? and not_added.empty?
      flash[:error] = _("No users selected")
    end
    respond_to do |format|
      format.html { redirect_to @return_path }
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
            modified << t('permissions.flash.fragment.user_and_role_change', :user => permission.entity.name,
                            :old_role => t(old_role.name, :scope=> :role_defs, :default => old_role.name),
                            :role => t(permission.role.name, :scope=> :role_defs, :default => permission.role.name))
          else
            not_modified << t('permissions.flash.fragment.user_and_role_change', :user => permission.entity.name,
                            :old_role => t(old_role.name, :scope=> :role_defs, :default => old_role.name) ,
                            :role => t(permission.role.name, :scope=> :role_defs, :default => permission.role.name))
          end
        end
      end
    end
    unless modified.empty?
      flash[:notice] = _("Successfully modified the following User Roles: %s") % modified.to_sentence
    end
    unless not_modified.empty?
      flash[:error] = _("Could not add these User Roles: %s") % not_modified.to_sentence
    end
    if modified.empty? and not_modified.empty?
      flash[:notice] = _("All User Roles already set; no changes needed")
    end
    respond_to do |format|
      format.html { redirect_to @return_path }
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
        deleted << t('permissions.flash.fragment.user_and_role', :user => p.entity.name,
                      :role => t(p.role.name, :scope=> :role_defs, :default => p.role.name))
      else
        not_deleted << t('permissions.flash.fragment.user_and_role', :user => p.entity.name,
                      :role => t(p.role.name, :scope=> :role_defs, :default => p.role.name))
      end
    end

    unless deleted.empty?
      flash[:notice] = _("Deleted the following Permission Grants: %s") % deleted.to_sentence
    end
    unless not_deleted.empty?
      flash[:error] = _("Could not delete these Permission Grants: %s") % not_deleted.to_sentence
    end
    respond_to do |format|
      format.html { redirect_to @return_path }
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

  def filter
    redirect_to_original({"permissions_preset_filter" => params[:permissions_preset_filter], "permissions_search" => params[:permissions_search]})
  end

  def filter_entities
    redirect_to_original({"entities_preset_filter" => params[:entities_preset_filter], "entities_search" => params[:entities_search]})
  end

  def profile_filter
    redirect_to_original({"profile_permissions_preset_filter" =>
                             params[:profile_permissions_preset_filter],
                          "profile_permissions_search" =>
                             (params[:profile_permissions_preset_filter].empty? ?
                              nil : params[:profile_permissions_search])})
  end

  private

  def load_entities
    sort_order = params[:sort_by].nil? ? "name" : params[:sort_by]
    @entities = paginate_collection(Entity.
      order(sort_column(Entity, sort_order)).
      apply_filters(:preset_filter_id => params[:entities_preset_filter],
                    :search_filter => params[:entities_search]),
                                    params[:page])
  end

  def load_headers
    @header = [
      { :name => '', :sortable => false },
      { :name => _("Name") },
      { :name => _("Role"), :sortable => false }
    ]
  end

  def set_permission_object (required_role=Privilege::PERM_SET)
    obj_type = params[:permission_object_type]
    id = params[:permission_object_id]
    @return_path = params[:return_path]
    @path_prefix = params[:path_prefix]
    @polymorphic_path_extras = params[:polymorphic_path_extras]
    @use_tabs = params[:use_tabs]
    unless obj_type or id
      @permission_object = BasePermissionObject.general_permission_scope
    end
    if obj_type && id
      if klass = ActiveRecord::Base.send(:subclasses).find{|c| c.name == obj_type}
        @permission_object = klass.find(id)
      else
        raise RuntimeError, "invalid permission object type #{obj_type}"
      end
    end
    raise RuntimeError, "invalid permission object" if @permission_object.nil?
    unless @return_path
      if @permission_object == BasePermissionObject.general_permission_scope
        @return_path = permissions_path(:return_from_permission_change => true)
        set_admin_users_tabs 'permissions'
      else
        @return_path = send("#{@path_prefix}polymorphic_path",
                            @permission_object.respond_to?(
                              :to_polymorphic_path_param) ?
                            @permission_object.to_polymorphic_path_param(
                              @polymorphic_path_extras) :
                            @permission_object,
                            @use_tabs == "yes" ? {:details_tab => :permissions,
                              :only_tab => true,
                              :return_from_permission_change => true} :
                             {:return_from_permission_change => true})
      end
    end
    require_privilege(required_role, @permission_object)
    set_permissions_header
  end
end
