class Admin::ProvidersController < ApplicationController
  before_filter :require_user
  before_filter :set_view_envs, :only => [:show, :index]

  def index
    @params = params
    @search_term = params[:q]
    if @search_term.blank?
      load_providers
      return
    end

    search = Provider.search do
      keywords(params[:q])
    end
    @providers = search.results
  end

  def new
    require_privilege(Privilege::PROVIDER_MODIFY)
    @provider = Provider.new
    kick_condor
  end

  def edit
    @provider = Provider.find_by_id(params[:id])
    require_privilege(Privilege::PROVIDER_MODIFY, @provider)
  end

  def show
    load_providers
    @provider = Provider.find(params[:id])
    @url_params = params.clone
    @tab_captions = ['Properties', 'HW Profiles', 'Realms', 'Provider Accounts', 'Services','History','Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show' }
    end
  end

  def create
    require_privilege(Privilege::PROVIDER_MODIFY)
    @provider = Provider.new(params[:provider])
    if params[:test_connection]
      test_connection(@provider)
      render :action => 'new'
    else
      @provider.set_cloud_type!
      if @provider.save && @provider.populate_hardware_profiles
        flash[:notice] = "Provider added."
        redirect_to admin_providers_path
      else
        flash[:notice] = "Cannot add the provider."
        render :action => "new"
      end
      kick_condor
    end
  end

  def update
   require_privilege(Privilege::PROVIDER_MODIFY)
   @provider = Provider.find_by_id(params[:id])
   previous_cloud_type = @provider.cloud_type
   @provider.update_attributes(params[:provider])
   if params[:test_connection]
     test_connection(@provider)
     render :action => 'edit'
   else
    @provider.set_cloud_type!
     if previous_cloud_type != @provider.cloud_type
      @provider.errors.add :url, "points to a different provider"
    end

     if @provider.errors.empty? and @provider.save
       flash[:notice] = "Provider updated."
       redirect_to admin_providers_path
     else
       flash[:notice] = "Cannot update the provider."
       render :action => 'edit'
     end
     kick_condor
   end
  end

  def multi_destroy
    Provider.destroy(params[:provider_selected])
    redirect_to admin_providers_url
  end

  def test_connection(provider)
    @provider.errors.clear
    if @provider.connect
      flash[:notice] = "Successfuly Connected to Provider"
    else
      flash[:notice] = "Failed to Connect to Provider"
      @provider.errors.add :url
    end
  end

  protected
  def set_view_envs
    @header = [{ :name => "Provider name", :sort_attr => :name },
               { :name => "Provider URL", :sort_attr => :name }
    ]
    @url_params = params.clone
  end

  def load_providers
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)
  end
end
