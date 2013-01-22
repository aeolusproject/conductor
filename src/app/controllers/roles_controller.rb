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

class RolesController < ApplicationController
  before_filter :require_user
  before_filter :load_roles, :only => [:show]

  def index
    require_privilege(Privilege::PERM_VIEW)
    clear_breadcrumbs
    save_breadcrumb(roles_path)
    load_roles
  end

  def new
    require_privilege(Privilege::PERM_SET)
    @role = Role.new
  end

  def create
    require_privilege(Privilege::PERM_SET)
    @role = Role.new(params[:role])

    # TODO: (lmartinc) Fix this and let user select the scope. Consult with sseago.
    @role.scope = BasePermissionObject.to_s if @role.scope.nil?

    if @role.save
      flash[:notice] = _("Role successfully saved.")
      redirect_to roles_path and return
    end

    render :action => 'new'
  end

  def show
    require_privilege(Privilege::PERM_VIEW)
    @role = Role.find(params[:id])

    @tab_captions = [_("Properties")]
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    save_breadcrumb(role_path(@role), @role.name)
    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
    end
  end

  def edit
    require_privilege(Privilege::PERM_SET)
    @role = Role.find(params[:id])
  end

  def update
    require_privilege(Privilege::PERM_SET)
    @role = Role.find(params[:id])

    if params[:commit] == "Reset"
      redirect_to edit_role_url(@role) and return
    end

    if @role.update_attributes(params[:role])
      flash[:notice] = _("Role updated successfully.")
      redirect_to roles_url and return
    end

    render :action => 'edit'
  end

  def multi_destroy
    deleted=[]
    not_deleted=[]
    require_privilege(Privilege::PERM_SET)
    Role.find(params[:role_selected]).each do |role|
      if role.destroy
        deleted << role.name
      else
        not_deleted << role.name
      end
    end

    unless deleted.empty?
      flash[:notice] = "#{_("These Roles were deleted:")} #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "#{_("Could not delete these Roles:")} #{not_deleted.join(', ')}"
    end

    redirect_to roles_url
  end

  def destroy
    require_privilege(Privilege::PERM_SET)
    Role.destroy(params[:id])
    redirect_to roles_url
  end

  protected

  def load_roles
    @roles = Role.paginate(:page => params[:page] || 1,
      :order => (sort_column(Role)+' '+ (sort_direction))
    )
  end

end
