class DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]
  before_filter :load_deployment, :only => [:edit, :update]

  viewstate :show do |default|
    default.merge!({
      :view => 'pretty',
    })
  end

  def index
    save_breadcrumb(deployments_path(:viewstate => viewstate_id))
    respond_to do |format|
      format.js { render :partial => 'list' }
      format.html
      format.json { render :json => @deployments }
    end
  end

  # It is expected that params[:pool_id] will be set on requests into this method
  def launch_new
    @pool = Pool.find(params[:pool_id]) or raise "Invalid pool"
    require_privilege(Privilege::CREATE, Deployment)
    @deployment = Deployment.new(:pool_id => @pool.id)
    @suggested_deployables = SuggestedDeployable.list_for_user(current_user, Privilege::USE)
    init_new_deployment_attrs
    respond_to do |format|
      format.js { render :partial => 'launch_new' }
      format.html
      format.json { render :json => @deployment }
    end
  end

  # launch_new will post here, but you can use this RESTfully as well
  def new
    @deployment = Deployment.new(params[:deployment])
    @pool = @deployment.pool
    @suggested_deployables = SuggestedDeployable.list_for_user(current_user, Privilege::USE)
    require_privilege(Privilege::CREATE, Deployment, @pool)
    url = get_deployable_url
    respond_to do |format|
      if @deployment.accessible_and_valid_deployable_xml?(url)
        format.js { render :partial => 'new' }
        format.html
        format.json { render :json => @deployment }
      else
        init_new_deployment_attrs
        format.js { render :partial => 'launch_new' }
        format.html { render :launch_new }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    @deployment = Deployment.new(params[:deployment])
    require_privilege(Privilege::CREATE, Deployment, @deployment.pool)
    @deployment.owner = current_user
    respond_to do |format|
      if @deployment.save
        status = @deployment.launch(current_user)
        if status[:errors].empty?
          flash[:notice] = "Deployment launched"
        else
          flash[:error] = {
            :summary  => "Failed to launch following assemblies:",
            :failures => status[:errors],
            :successes => status[:successes]
          }
        end
        format.js { render :partial => 'properties' }
        format.html { redirect_to deployment_path(@deployment) }
        format.json { render :json => @deployment, :status => :created }
      else
        # We need @pool to re-display the form
        @pool = @deployment.pool
        flash.now[:warning] = "Deployment launch failed"
        init_new_deployment_attrs
        format.js { launch_new }
        format.html { render :action => 'new' }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @deployment = Deployment.find(params[:id])
    require_privilege(Privilege::VIEW, @deployment)
    init_new_deployment_attrs
    save_breadcrumb(deployment_path(@deployment, :viewstate => viewstate_id), @deployment.name)
    @failed_instances = @deployment.instances.select {|instance| instance.state == Instance::STATE_CREATE_FAILED || instance.state == Instance::STATE_ERROR}
    @view = filter_view? ? 'filter_view_show' : 'pretty_view_show'
    respond_to do |format|
      format.js { render :partial => @view }
      format.html { render :action => 'show'}
      format.json { render :json => @deployment }
    end
  end

  def edit
    require_privilege(Privilege::MODIFY, @deployment)
    respond_to do |format|
      format.js { render :partial => 'edit' }
      format.html
      format.json { render :json => @deployment }
    end
  end

  # TODO - This should eventually support updating multiple objects
  def update
    attrs = {}
    params[:deployment].each_pair{|k,v| attrs[k] = v if Deployment::USER_MUTABLE_ATTRS.include?(k)}
    respond_to do |format|
      if check_privilege(Privilege::MODIFY, @deployment) and @deployment.update_attributes(attrs)
        flash[:success] = t('deployments.updated', :count => 1, :list => @deployment.name)
        format.js { render :partial => 'properties' }
        format.html { redirect_to @deployment }
        format.json { render :json => @deployment }
      else
        flash[:error] = t('deployments.not_updated', :count => 1, :list => @deployment.name)
        format.js { render :partial => 'edit' }
        format.html { render :action => :edit }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
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
    respond_to do |format|
      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.html { redirect_to deployments_url }
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
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
    respond_to do |format|
      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.html { redirect_to pools_path(:details_tab => 'deployments', :filter_view => filter_view?) }
      format.json { render :json => {:success => notices, :errors => errors} }
    end
  end

  # Quick method to check if a deployment name is taken or not
  # TODO - The AJAX calls here have a potential race condition; might want to include params[:name]
  # in the output to help catch this and discard output if appropriate
  def check_name
    deployment = Deployment.find_by_name(params[:name])
    render :text => deployment.nil?.to_s
  end

  private
  def load_deployments
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

  def get_deployable_url
    if params[:suggested_deployable_id].to_s == 'other'
      url = params[:deployable] ? params[:deployable][:url] : nil
    else
      sdeployable = SuggestedDeployable.find(params[:suggested_deployable_id])
      require_privilege(Privilege::USE, sdeployable)
      url = sdeployable.url
    end
    url
  end
end
