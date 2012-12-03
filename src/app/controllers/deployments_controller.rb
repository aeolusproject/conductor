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

class DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]
  before_filter :load_deployment, :only => [:edit, :update]
  before_filter :check_inaccessible_instances, :only => :multi_stop
  before_filter :set_backlink, :only => [:launch_new, :launch_time_params, :create]

  viewstate :show do |default|
    default.merge!({
      :view => 'pretty',
    })
  end

  def index
    save_breadcrumb(deployments_path(:viewstate => viewstate_id))
    @title = _("Deployments")
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.json { render :json => @deployments }
      format.xml { @pool = @pools.first if params[:pool_id] }
    end
  end

  # It is expected that params[:pool_id] will be set on requests into this method
  def launch_new
    @title = _("New Deployment")

    if params[:deployment].present?
      @deployment = Deployment.new(params[:deployment])
      @pool = @deployment.pool
    else
      @pool = Pool.find(params[:pool_id]) or raise "Invalid pool"
      @deployment = Deployment.new(:pool_id => @pool.id)
    end

    require_privilege(Privilege::CREATE, Deployment, @pool)
    unless @pool.enabled
      flash[:warning] = _("Cannot launch a Deployment in this Pool. The Pool has been disabled.")
      redirect_to pool_path(@pool) and return
    end


    init_new_deployment_attrs
    respond_to do |format|
      format.html
      format.js { render :partial => 'launch_new' }
      format.json { render :json => @deployment }
    end
  end



  def launch_time_params
    @title = _("New Deployment")

    @deployment = Deployment.new(params[:deployment])
    @pool = @deployment.pool
    init_new_deployment_attrs

    if @deployable.nil?
      @deployment.errors.add(:base, _("You need to select a Deployable"))
      render :launch_new and return
    end

    @deployment.deployable_xml = DeployableXML.new(@deployable.xml)
    @deployment.owner = current_user

    unless @deployment.valid? and params.has_key?(:deployable_id)
      @deployment.errors.add(:base, _("You need to select a Deployable")) unless params.has_key?(:deployable_id)
      render :launch_new and return
    end

    require_privilege(Privilege::CREATE, Deployment, @pool)
    require_privilege(Privilege::USE, @deployable)
    img, img2, missing, d_errors = @deployable.get_image_details
    flash[:error] = d_errors unless d_errors.empty?

    unless @deployable && @deployable.xml && @deployment.valid_deployable_xml?(@deployable.xml) && d_errors.empty?
      render 'launch_new' and return
    end

    load_assemblies_services

    if @services.empty? or @services.all? {|s, a| s.parameters.empty?}
      # we can skip the launch-time parameters screen
      @errors = @deployment.check_assemblies_matches(current_session,
                                                     current_user)
      set_errors_flash(@errors)
      @additional_quota = count_additional_quota(@deployment)
      render 'overview' and return
    end

    # check that type attrs on service params are used properly
    warnings = @deployable.check_service_params_types
    unless warnings.empty?
      flash[:warning] ||= []
      flash[:warning] = [flash[:warning]] if flash[:warning].kind_of? String
      flash[:warning]+=warnings
    end

  end

  def overview
    @title = _("New Deployment")
    @deployment = Deployment.new(params[:deployment])
    @pool = @deployment.pool
    init_new_deployment_attrs
    require_privilege(Privilege::CREATE, Deployment, @pool)
    require_privilege(Privilege::USE, @deployable)
    @launch_parameters_encoded = Base64.encode64(ActiveSupport::JSON.encode(@deployment.launch_parameters))
    img, img2, missing, d_errors = @deployable.get_image_details
    flash[:error] = d_errors unless d_errors.empty?

    respond_to do |format|
      if @deployable.xml && @deployment.valid_deployable_xml?(@deployable.xml) && d_errors.empty?
        @errors = @deployment.check_assemblies_matches(current_session,
                                                       current_user)
        set_errors_flash(@errors)
        @additional_quota = count_additional_quota(@deployment)

        format.html
        format.js { render :partial => 'overview' }
        format.json { render :json => @deployment }
      else
        format.html { render :launch_new }
        format.js { render :partial => 'launch_new' }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    @deployment = Deployment.new(params[:deployment])
    @pool = @deployment.pool
    require_privilege(Privilege::CREATE, Deployment, @pool)

    if params[:launch_parameters_encoded].present?
      @deployment.launch_parameters = JSON.load(
        Base64.decode64(params[:launch_parameters_encoded]))
    end

    init_new_deployment_attrs
    require_privilege(Privilege::USE, @deployable)
    @deployment.deployable_xml = @deployable.xml
    @deployment.owner = current_user

    if params.delete(:commit) == _("Back")
      load_assemblies_services
      view = @deployment.launch_parameters.blank? ?
        'launch_new' : 'launch_time_params'
      render view
      return
    end
    return unless check_deployable_images

    respond_to do |format|
      if @deployment.create_and_launch(current_session, current_user)
        format.html do
          flash[:notice] = _("Deployment launched.")
          if @deployment.errors.present?
            flash[:error] = @deployment.errors.full_messages
          end
          redirect_to deployment_path(@deployment)
        end
        format.js { render :partial => 'properties' }
        format.json { render :json => @deployment, :status => :created }
      else
        # if rollback was done, we create new @deployment object instead of
        # trying restoring the original @deployment's state
        # TODO: replace with 'initialize_dup' method after upgrading
        # to newer Rails
        @deployment = @deployment.copy_as_new

        # TODO: put deployment's errors into flash or display inside page?
        format.html do
          flash.now[:warning] = _("Deployment launch failed.")
          render :action => 'overview'
        end
        format.js { render :partial => 'overview' }
        format.json { render :json => @deployment.errors,
                             :status => :unprocessable_entity }
      end
    end
  end

  def show
    @deployment = Deployment.find(params[:id])
    @title = _("%s Deployment") % @deployment.name
    require_privilege(Privilege::VIEW, @deployment)
    init_new_deployment_attrs
    save_breadcrumb(deployment_path(@deployment, :viewstate => viewstate_id), @deployment.name)
    @failed_instances = @deployment.failed_instances.list(sort_column(Instance), sort_direction)
    if filter_view?
      @view = 'instances/list'
      params[:instances_preset_filter] = "" unless params[:instances_preset_filter]
      @instances = paginate_collection(Instance.apply_filters(:preset_filter_id => params[:instances_preset_filter],
                                                              :search_filter => params[:instances_search]).
                                                list(sort_column(Instance), sort_direction).
                                                where("instances.deployment_id" => @deployment.id),
                                       params[:page], PER_PAGE)
    else
      @view = 'pretty_view_show'
      @instances = paginate_collection(Instance.list(sort_column(Instance), sort_direction).where("instances.deployment_id" => @deployment.id),
                                       params[:page], PER_PAGE)
    end
    #TODO add links to real data for history, services
    @tabs = [{:name => _("Instances"), :view => @view,
               :id => 'instances', :count => @deployment.instances.count,
               :pretty_view_toggle => 'enabled'},
             {:name => _("Properties"), :view => 'properties',
               :id => 'properties', :pretty_view_toggle => 'disabled'},
             {:name => _("History"), :view => 'history', :id => 'history',
               :pretty_view_toggle => 'disabled'},
    ]
    add_permissions_tab(@deployment)
    details_tab_name = params[:details_tab].blank? ? 'instances' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    if @details_tab[:id] == 'history'
      @events = @deployment.events_of_deployment_and_instances
    end
    if params[:details_tab]
      @view = @details_tab[:view]
    end
    respond_to do |format|
      format.html { render :action => 'show'}
      format.js   { render :partial => @details_tab[:view] }
      format.json { render :json => @deployment }
      format.xml
    end
  end

  def edit
    require_privilege(Privilege::MODIFY, @deployment)
    respond_to do |format|
      format.html
      format.js { render :partial => 'edit' }
      format.json { render :json => @deployment }
    end
  end

  # TODO - This should eventually support updating multiple objects
  def update
    attrs = {}
    params[:deployment].each_pair{|k,v| attrs[k] = v if Deployment::USER_MUTABLE_ATTRS.include?(k)}
    respond_to do |format|
      if check_privilege(Privilege::MODIFY, @deployment) and @deployment.update_attributes(attrs)
        flash[:success] = _("The Deployment %s was successfully updated.") % @deployment.name
        format.html { redirect_to @deployment }
        format.js { render :partial => 'properties' }
        format.json { render :json => @deployment }
      else
        flash[:error] = _("The Deployment %s could not be updated.") % @deployment.name
        format.html { render :action => :edit }
        format.js { render :partial => 'edit' }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    deployment = Deployment.find(params[:id])
    cant_stop = false
    errors = []
    begin
      require_privilege(Privilege::MODIFY, deployment)
      if deployment.not_stoppable_or_destroyable_instances.empty?
        Delayed::Job.enqueue DeploymentDestroy.new(deployment)
      else
        cant_stop = true
        errors = deployment.not_stoppable_or_destroyable_instances.map {|i|
          _("The instance %s is in state %s.") % [i.name, i.state]}

      end
    rescue
      errors = _("The Deployment %s could not be deleted: %s") % [deployment.name, $!.message]
    end

    respond_to do |format|
      format.js do
        load_deployments
        render :partial => 'list'
      end

      format.html do
        if errors.empty?
          flash[:success] = _("The Deployment %s was scheduled for deletion.") % deployment.name
        elsif cant_stop
          flash[:error] = {:summary => _("The Deployment %s can not be deleted because following instances can not be stopped:") % deployment.name,
                           :failures => errors}
        else
          flash[:error] = errors
        end
        redirect_to pools_url(:view => 'filter', :details_tab => 'deployments')
      end

      format.json { render :json => {:success => errors.empty?,
                                     :errors => errors} }
    end
  end

  def multi_destroy
    destroyed = []
    errors = []

    ids = Array(params[:deployments_selected])
    Deployment.find(ids).each do |deployment|
      require_privilege(Privilege::MODIFY, deployment)
      if deployment.not_stoppable_or_destroyable_instances.empty?
        Delayed::Job.enqueue DeploymentDestroy.new(deployment)
        destroyed << deployment.name
      else
        errors << _("The Deployment %s could not be deleted: %s") % [deployment.name, _("All Instances must be stopped or running")]
      end

    end
    respond_to do |format|
      format.html do
        if ids.empty?
          flash[:error] = _("You must select one or more Deployments.")
        elsif errors.present?
          flash[:error] = errors
        end
        flash[:success] = n_("The Deployment %s was scheduled for deletion.","The Deployments %s were scheduled for deletion.",destroyed.size) % destroyed.to_sentence if destroyed.present?
        redirect_to params[:backlink] ||
          pools_url(:view => 'filter', :details_tab => 'deployments')
      end

      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.json { render :json => {:success => destroyed, :errors => errors} }
    end
  end

  def multi_stop
    notices = []
    errors = []

    @deployments_to_stop.each do |deployment|
      # TODO: move all this logic to model
      unless deployment.can_stop?
        errors << _("The Deployment %s could not be stopped. Only running Deployments can be stopped.") % deployment.name
        next
      end
      deployment.state = Deployment::STATE_SHUTTING_DOWN
      deployment.save!
      deployment.instances.each do |instance|
        log_prefix = "#{_("Deployment")}: #{instance.deployment.name}, #{_("Instance")}:  #{instance.name}"
        begin
          require_privilege(Privilege::USE, instance)
          if @inaccessible_instances.include?(instance)
            instance.forced_stop(current_user)
            notices << "#{log_prefix}: #{_("state changed to stopped.")}"
          else
            instance.stop(current_user)
            notices << "#{log_prefix}: #{_("stop action was successfully queued.")}"
          end
        rescue Exception => ex
          errors << "#{log_prefix}: #{ex}"
          log_backtrace(ex)
        end
      end
    end
    # If nothing is selected, display an error message:
    errors = _("You must select one or more Deployments.") if notices.blank? and errors.blank?
    flash[:notice] = notices unless notices.blank?
    flash[:error] = errors unless errors.blank?
    respond_to do |format|
      format.html { redirect_to pools_path(:details_tab => 'deployments', :filter_view => filter_view?) }
      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.json { render :json => {:success => notices, :errors => errors} }
    end
  end

  # Quick method to check if a deployment name is taken or not
  # TODO - The AJAX calls here have a potential race condition; might want to include params[:name]
  # in the output to help catch this and discard output if appropriate
  def check_name
    render :text => params[:name].empty? ? false : Deployment.find_by_name(params[:name]).nil?
  end

  def launch_from_catalog
    @catalog = Catalog.find(params[:catalog_id])
    @deployables = @catalog.deployables.
      list_for_user(current_session, current_user, Privilege::VIEW).
      paginate(:page => params[:page] || 1, :per_page => 6)
    require_privilege(Privilege::VIEW, @catalog)
  end

  def filter
    redirect_to_original({"deployments_preset_filter" => params[:deployments_preset_filter], "deployments_search" => params[:deployments_search]})
  end

  private

  def check_inaccessible_instances
    @deployments_to_stop = Deployment.find(params[:deployments_selected] || [])
    @inaccessible_instances = Deployment.stoppable_inaccessible_instances(@deployments_to_stop)
    if params[:terminate].blank? and @inaccessible_instances.any?
      respond_to do |format|
        format.html { render :action => :confirm_terminate }
        format.json { render :json => {:inaccessbile_instances => @inaccessible_instances}, :status => :unprocessable_entity }
      end
      return false
    end
    return true
  end

  def load_deployments
    @deployments_header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => '', :class => 'alert', :sortable => false },
      { :name => _("Deployment Name"), :sortable => false },
      { :name => _("Deployed on"), :sortable => false },
      { :name => _("Base Deployable"), :sortable => false },
      { :name => _("State"), :sortable => false },
      { :name => _("Instances"), :class => 'center', :sortable => false },
      { :name => _("Pool"), :sortable => false },
      { :name => _("Owner"), :sortable => false },
      { :name => _("Provider"), :sortable => false }
    ]

    pool_scope = params[:pool_id] ? Pool.where(:id => params[:pool_id]) : Pool
    @pools = pool_scope.list_for_user(current_session, current_user,
                                      Privilege::CREATE, Deployment)

    unpaginated_deployments = Deployment.includes(:owner, :pool, :instances).
      apply_filters(:preset_filter_id => params[:deployments_preset_filter],
                    :search_filter => params[:deployments_search]).
      list_for_user(current_session, current_user, Privilege::VIEW).
      where('deployments.pool_id' => @pools).
      order(sort_column(Deployment, "deployments.name") +' '+ sort_direction)

    # pagination is currently not used for XML REST API
    @deployments = if request.format.xml?
                     unpaginated_deployments
                   else
                     paginate_collection(unpaginated_deployments, params[:page], PER_PAGE)
                   end
  end

  def count_additional_quota(deployment)
    assembly_count = deployment.deployable_xml.assemblies.count
    @additional_quota = deployment.pool.quota.percentage_used(assembly_count)
  end

  def load_deployment
    @deployment = Deployment.find(params[:id])
    @pool = @deployment.pool
  end

  def set_errors_flash(errors)
    unless errors.empty?
      flash.now[:error] = {
          :failures => errors
      }
    end
  end

  def init_new_deployment_attrs
    @deployables = Deployable.includes({:catalogs => :pool}).
      list_for_user(current_session, current_user, Privilege::USE).
      select{|d| d.catalogs.collect{|c| c.pool}.include?(@pool)}
    @pools = Pool.list_for_user(current_session, current_user,
                                Privilege::CREATE, Deployment)
    @deployable = params[:deployable_id] ? Deployable.find(params[:deployable_id]) : nil
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
        :include => :architecture,
        :conditions => {:provider_id => nil}
    )
  end

  def load_assemblies_services
    @services = []
    @deployment.deployable_xml.assemblies.each do |assembly|
      assembly.services.each do |service|
        @services << [service, assembly.name]
      end
    end
  end

  def check_deployable_images
    image_details, images, missing_images, deployable_errors = @deployable.get_image_details
    return true if deployable_errors.empty?
    respond_to do |format|
      flash.now[:warning] = _("Deployment launch failed.")
      flash[:error] = deployable_errors
      format.html { render :action => 'overview' }
      format.js { render :partial => 'overview' }
      format.json { render :json => deployable_errors, :status => :unprocessable_entity }
    end
    false
  end

  def set_backlink
    if params[:backlink].present?
      recognize_path_with_relative_url_root(params[:backlink])
      @backlink = params[:backlink]
    end
  rescue
    logger.error "Value of backlink is not recognized by the application routing"
  end

end
