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
      format.html
      format.js { render :partial => 'list' }
      format.json { render :json => @deployments }
    end
  end

  # It is expected that params[:pool_id] will be set on requests into this method
  def launch_new
    @pool = Pool.find(params[:pool_id]) or raise "Invalid pool"
    require_privilege(Privilege::CREATE, Deployment, @pool)
    unless @pool.enabled
      flash[:warning] = t 'deployments.disabled_pool'
      redirect_to pool_path(@pool) and return
    end

    @deployment = Deployment.new(:pool_id => @pool.id)
    @catalog_entries = CatalogEntry.list_for_user(current_user, Privilege::USE)
    init_new_deployment_attrs
    respond_to do |format|
      format.html
      format.js { render :partial => 'launch_new' }
      format.json { render :json => @deployment }
    end
  end

  # launch_new will post here, but you can use this RESTfully as well
  def new
    @deployment = Deployment.new(params[:deployment])
    @pool = @deployment.pool
    @catalog_entries = CatalogEntry.list_for_user(current_user, Privilege::USE)
    require_privilege(Privilege::CREATE, Deployment, @pool)
    url = get_deployable_url
    respond_to do |format|
      if @deployment.accessible_and_valid_deployable_xml?(url)
        errors = @deployment.check_assemblies_matches(current_user)
        unless errors.empty?
          flash[:error] = {
            :summary => "Some assemblies will not be launched:",
            :failures => errors
          }
        end
        format.html
        format.js { render :partial => 'new' }
        format.json { render :json => @deployment }
      else
        init_new_deployment_attrs
        format.html { render :launch_new }
        format.js { render :partial => 'launch_new' }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    @deployment = Deployment.new(params[:deployment])
    require_privilege(Privilege::CREATE, Deployment, @deployment.pool)
    @deployment.owner = current_user
    url = get_deployable_url
    @deployment.accessible_and_valid_deployable_xml?(url) unless url.nil?
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
        format.html { redirect_to deployment_path(@deployment) }
        format.js do
          @deployment_properties = @deployment.properties
          render :partial => 'properties'
        end
        format.json { render :json => @deployment, :status => :created }
      else
        # We need @pool to re-display the form
        @pool = @deployment.pool
        flash.now[:warning] = "Deployment launch failed"
        init_new_deployment_attrs
        format.html { render :action => 'new' }
        format.js { launch_new }
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
    if filter_view?
      @view = 'instances/list'
      @instances = @deployment.instances
      @hide_stopped = @viewstate && @viewstate.state['hide_stopped'] == 'true'
      if @hide_stopped
        @instances.delete_if { |i| i.state == Instance::STATE_STOPPED }
      end
    else
      @view = 'pretty_view_show'
    end
    #TODO add links to real data for history, permissions, services
    @tabs = [{:name => 'Instances', :view => @view, :id => 'instances', :count => @deployment.instances.count},
             #{:name => 'Services', :view => @view, :id => 'services'},
             #{:name => 'History', :view => 'history', :id => 'history'},
             {:name => 'Properties', :view => 'properties', :id => 'properties'}
             #{:name => 'Permissions', :view => 'permissions', :id => 'permissions'}
    ]
    details_tab_name = params[:details_tab].blank? ? 'instances' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    @deployment_properties = @deployment.properties
    if params[:details_tab]
      @view = @details_tab[:view]
    end
    respond_to do |format|
      format.html { render :action => 'show'}
      format.js   { render :partial => @details_tab[:view] }
      format.json { render :json => @deployment }
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
        flash[:success] = t('deployments.updated', :count => 1, :list => @deployment.name)
        format.html { redirect_to @deployment }
        format.js do
          @deployment_properties = @deployment.properties
          render :partial => 'properties'
        end
        format.json { render :json => @deployment }
      else
        flash[:error] = t('deployments.not_updated', :count => 1, :list => @deployment.name)
        format.html { render :action => :edit }
        format.js { render :partial => 'edit' }
        format.json { render :json => @deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    deployment = Deployment.find(params[:id])
    if check_privilege(Privilege::MODIFY, deployment)
      begin
        deployment.stop_instances_and_destroy!
        flash[:success] = t('deployments.deleted', :list => deployment.name, :count => 1)
      rescue
        flash[:error] = t('deployments.not_deleted', :list => deployment.name, :count => 1)
      end
    else
      flash[:error] = t('deployments.not_deleted', :list => deployment.name, :count => 1)
    end
    respond_to do |format|
      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.html { redirect_to pools_url(:view => 'filter', :details_tab => 'deployments') }
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  def multi_destroy
    destroyed = []
    failed = []
    Deployment.find(params[:deployments_selected] || []).each do |deployment|
      if check_privilege(Privilege::MODIFY, deployment)
        begin
          deployment.stop_instances_and_destroy!
          destroyed << deployment.name
        rescue
          failed << deployment.name
        end
      else
        failed << deployment.name
      end
    end
    # If nothing is selected, display an error message:
    flash[:error] = t('deployments.none_selected') if failed.blank? && destroyed.blank?
    flash[:success] = t('deployments.deleted', :list => destroyed.join(', '), :count => destroyed.size) if destroyed.present?
    flash[:error] = t('deployments.not_deleted', :list => failed, :count => failed.size) if failed.present?
    respond_to do |format|
      format.html { redirect_to params[:backlink] || pools_url(:view => 'filter', :details_tab => 'deployments') }
      format.js do
        load_deployments
        render :partial => 'list'
      end
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  def multi_stop
    notices = ""
    errors = ""
    Deployment.find(params[:deployments_selected] || []).each do |deployment|
      deployment.instances.each do |instance|
        begin
          require_privilege(Privilege::USE,instance)
          unless instance.valid_action?('stop')
            raise ActionError.new("stop is an invalid action.")
          end

          #permissons check here
          @task = instance.queue_action(current_user, 'stop')
          unless @task
            raise ActionError.new("stop cannot be performed on this instance.")
          end
          Taskomatic.stop_instance(@task)
          notices << "Deployment: #{instance.deployment.name}, Instance:  #{instance.name}: stop action was successfully queued.<br/>"
        rescue Exception => err
          errors << "Deployment: #{instance.deployment.name}, Instance: #{instance.name}: " + err + "<br/>"
        end
      end
    end
    # If nothing is selected, display an error message:
    errors = t('deployments.none_selected') if errors.blank? && notices.blank?
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
    deployment = Deployment.find_by_name(params[:name])
    render :text => deployment.nil?.to_s
  end

  private
  def load_deployments
    @deployments = Deployment.paginate(:page => params[:page] || 1,
      :order => (params[:order_field] || 'name')  +' '+ (params[:order_dir] || 'asc')
    )
    @deployments_header = [
      { :name => '', :sortable => false },
      { :name => '', :sortable => false },
      { :name => t("deployments.deployment_name"), :sortable => false },
      { :name => t("pools.index.deployed_on"), :sortable => false },
      { :name => t("deployables.index.base_deployable"), :sortable => false },
      { :name => t("instances.instances"), :sortable => false },
      { :name => t("pools.index.pool"), :sortable => false },
      { :name => t("pools.index.owner"), :sortable => false },
      { :name => t("providers.provider"), :sortable => false }
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
    @pools = Pool.list_for_user(current_user, Privilege::CREATE, :target_type => Deployment)
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {:provider_id => nil}
    )
  end

  def get_deployable_url
    if !params.has_key?(:catalog_entry_id)
      return nil
    elsif params[:catalog_entry_id].to_s == 'other'
      return params[:deployable_url]
    else
      c_entry = CatalogEntry.find(params[:catalog_entry_id])
      require_privilege(Privilege::USE, c_entry)
      return c_entry.url
    end
  end
end
