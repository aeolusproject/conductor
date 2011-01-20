class Admin::RolesController < ApplicationController
  before_filter :require_user
  before_filter :load_roles, :only => [:show]
  before_filter :load_params_and_headers, :only => [:index]

  def index
    @search_term = params[:q]
    if @search_term.blank?
      load_roles
      return
    end

    search = Role.search() do
      keywords(params[:q])
    end
    @roles = search.results
  end

  def create
    require_privilege(Privilege::PERM_SET)
    @role = Role.new(params[:role])

    # TODO: (lmartinc) Fix this and let user select the scope. Consult with sseago.
    @role.scope = BasePermissionObject.to_s if @role.scope.nil?

    if @role.save
      flash[:notice] = 'Role successfully saved!'
      redirect_to admin_roles_path and return
    end

    render :action => 'new'
  end

  def show
    require_privilege(Privilege::PERM_VIEW)
    @role = Role.find(params[:id])

    @url_params = params.clone
    @tab_captions = ['Properties']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
      format.html { render :partial => @details_tab }
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
      redirect_to edit_admin_role_url(@role) and return
    end

    if @role.update_attributes(params[:role])
      flash[:notice] = 'Role updated successfully!'
      redirect_to admin_roles_url and return
    end

    render :action => 'edit'
  end

  def multi_destroy
    require_privilege(Privilege::PERM_SET)
    Role.destroy(params[:role_selected])
    redirect_to admin_roles_url
  end

  protected

  def load_params_and_headers
    @header = [
      { :name => "Role name", :sort_attr => :name }
    ]
    @url_params = params.clone
  end

  def load_roles
    @roles = Role.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

end
