class DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]
  before_filter :load_deployment, :only => [:edit, :update]

  def index
  end

  def launch_new
    @launchable_deployables = []
    Deployable.all.each do |deployable|
      @launchable_deployables << deployable if deployable.launchable?
    end
  end

  def new
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(:deployable_id => params[:deployable_id])
    if @deployment.deployable.assemblies.empty?
      flash[:warning] = "Deployable must have at least one assembly"
      redirect_to deployments_path
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
      errors = @deployment.launch(params[:hw_profiles] || {}, current_user)
      unless errors.empty?
        flash[:error] = {
          :summary  => "Failed to launch following assemblies:",
          :failures => errors
        }
      end
      redirect_to deployment_path(@deployment)
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
    @tab_captions = ['Properties', 'Instances', 'Provider Services', 'Required Services', 'History', 'Permissions','Operation']
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

  def edit
    require_privilege(Privilege::MODIFY, @deployment)
  end

  # TODO - This should eventually support updating multiple objects
  def update
    attrs = {}
    params[:deployment].each_pair{|k,v| attrs[k] = v if Deployment::USER_MUTABLE_ATTRS.include?(k)}
    if check_privilege(Privilege::MODIFY, @deployment) and @deployment.update_attributes(attrs)
      flash[:success] = t('deployments.updated', :count => 1, :list => @deployment.name)
      redirect_to @deployment
    else
      flash[:error] = t('deployments.not_updated', :count => 1, :list => @deployment.name)
      render :action => :edit
    end
  end

  def destroy
    destroyed = []
    failed = []
    Deployment.find(ids_list).each do |deployment|
      if check_privilege(Privilege::MODIFY, deployment) && deployment.destroyable?
        deployment.destroy
        destroyed << deployment.name
      else
        failed << deployment.name
      end
    end
    flash[:success] = t('deployments.deleted', :list => destroyed, :count => destroyed.size) if destroyed.present?
    flash[:error] = t('deployments.not_deleted', :list => failed, :count => failed.size) if failed.present?
    redirect_to deployments_url
  end

  def multi_stop
    notices = ""
    errors = ""
    Deployment.find(params[:deployments_selected]).each do |deployment|
      deployment.instances.each do |instance|
        begin
          require_privilege(Privilege::USE,instance)
          unless instance.valid_action?('stop')
            raise ActionError.new("stop is an invalid action.")
          end

          # not sure if task is used as everything goes through condor
          #permissons check here
          @task = instance.queue_action(@current_user, 'stop')
          unless @task
            raise ActionError.new("stop cannot be performed on this instance.")
          end
          condormatic_instance_stop(@task)
          notices << "Deployment: #{instance.deployment.name}, Instance:  #{instance.name}: stop action was successfully queued.<br/>"
        rescue Exception => err
          errors << "Deployment: #{instance.deployment.name}, Instance: #{instance.name}: " + err + "<br/>"
        end
      end
    end
    flash[:notice] = notices unless notices.blank?
    flash[:error] = errors unless errors.blank?
    redirect_to deployments_path
  end

  private
  def load_deployments
    @url_params = params
    @deployments = Deployment.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name')  +' '+ (params[:order_dir] || 'asc')
    )
    @header = [
      { :name => "", :sort_attr => :name },
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

  def load_deployment
    @deployment = Deployment.find(params[:id])
  end

  def init_new_deployment_attrs
    @pools = Pool.list_for_user(@current_user, Privilege::CREATE, :target_type => Deployment)
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {:provider_id => nil}
    )
  end
end
