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

class RolesController < ApplicationController
  before_filter :require_user
  before_filter :load_roles, :only => [:show]

  def index
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
      flash[:notice] = 'Role successfully saved!'
      redirect_to roles_path and return
    end

    render :action => 'new'
  end

  def show
    require_privilege(Privilege::PERM_VIEW)
    @role = Role.find(params[:id])

    @tab_captions = ['Properties']
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
      flash[:notice] = 'Role updated successfully!'
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
      flash[:notice] = "These Roles were deleted: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "Could not deleted these Roles: #{not_deleted.join(', ')}"
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
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

end
