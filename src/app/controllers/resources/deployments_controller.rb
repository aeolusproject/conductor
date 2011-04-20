class Resources::DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]

  def index
  end

  def new
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(:deployable_id => params[:deployable_id])
    if @deployment.deployable.assemblies.empty?
      flash[:warning] = "Deployable must have at least one assembly"
      redirect_to resources_deployments_path
    else
      init_new_deployment_attrs
    end
  end

  def create
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(params[:deployment])
    @deployment.owner = current_user
    if @deployment.save
      flash[:notice] = "Deployment launched"
      errors = @deployment.launch(params[:hw_profiles], current_user)
      unless errors.empty?
        flash[:error] = {
          :summary  => "Failed to launch following assemblies:",
          :failures => errors
        }
      end
      redirect_to resources_deployment_path(@deployment)
    else
      flash.now[:warning] = "Deployment launch failed"
      init_new_deployment_attrs
      render :new
    end
  end

  def show
    @deployment = Deployment.find(params[:id])
    require_privilege(Privilege::VIEW, @deployment)
    init_new_deployment_attrs
    @tab_captions = ['Properties', 'Instances', 'Provider Services', 'Required Services', 'History', 'Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
    end
  end

  private
  def load_deployments
    @url_params = params
    @deployments = Deployment.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name')  +' '+ (params[:order_dir] || 'asc')
    )
    @header = [
      { :name => "Deployment name", :sort_attr => :name },
      { :name => "Deployable", :sortable => false },
      { :name => "Owner", :sort_attr => "owner.login"},
      { :name => "Running Since", :sort_attr => :running_since },
      { :name => "Pool", :sort_attr => "pool.name" }
    ]
    @pools = Pool.list_for_user(current_user, Privilege::CREATE, :target_type => Deployment)
    @deployments = Deployment.all(:include => :owner,
                              :conditions => {:pool_id => @pools},
                              :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

  def init_new_deployment_attrs
    @pools = Pool.list_for_user(@current_user, Privilege::CREATE, :target_type => Deployment)
    @realms = FrontendRealm.all
    # FIXME: temporary for debugging
    #arch = @deployment.deployable.assemblies.first.templates.first.architecture
    arch = 'x86_64'
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {
        :provider_id => nil,
        'hardware_profile_properties.value' => arch
      }
    )
  end
end
