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

class PoolsController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pools, :only => [:show]

  viewstate :index do |default|
    default.merge!({
      :view => 'pretty',
      :hide_stopped => 'true',
    })
  end

  viewstate :show do |default|
    default.merge!({
      :view => 'pretty',
    })
  end

  def index
    clear_breadcrumbs
    save_breadcrumb(pools_path(:viewstate => viewstate_id))

    @user_pools = Pool.list_for_user(current_user, Privilege::VIEW)
    @user_pool_families = PoolFamily.list_for_user(current_user, Privilege::VIEW)
    if filter_view?
      @tabs = [{:name => "#{t'pools.pools'}", :view => 'list', :id => 'pools'},
               {:name => "#{t'deployments.deployments'}", :view => 'deployments/list', :id => 'deployments'},
               {:name => "#{t'instances.instances'}", :view => 'instances/list', :id => 'instances'},
      ]
      details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
      @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
      case @details_tab[:id]
      when 'pools'
        @pools = Pool.list(sort_column(Pool), sort_direction)
      when 'instances'
        @instances = Instance.list(sort_column(Instance), sort_direction)
        @hide_stopped = @viewstate && @viewstate.state['hide_stopped'] == 'true'
        if @hide_stopped
          @instances.delete_if { |i| i.state == Instance::STATE_STOPPED }
        end
      when 'deployments'
        @deployments = Deployment.list(sort_column(Deployment), sort_direction)
      end
    else
      @pools = Pool.list(sort_column(Pool), sort_direction)
    end

    statistics
    respond_to do |format|
      format.html { @view = filter_view? ? 'layouts/tabpanel' : 'pretty_list' }
      format.js do
        if filter_view?
          render :partial => params[:only_tab] == "true" ? @details_tab[:view] : 'layouts/tabpanel'
        else
          render :partial => 'pretty_list'
        end
      end
      format.json { render :json => @pools }
    end
  end

  def show
    @pool = Pool.find(params[:id])
    save_breadcrumb(pool_path(@pool, :viewstate => viewstate_id), @pool.name)
    require_privilege(Privilege::VIEW, @pool)
    @statistics = @pool.statistics
    @view = filter_view? ? 'deployments/list' : 'deployments/pretty_view' unless params[:details_tab]
    if params[:details_tab] == 'deployments'
      @view = filter_view? ? 'deployments/list' : 'deployments/pretty_view'
    end

    #TODO add links to real data for history,properties,permissions
    @tabs = [{:name => "#{t'deployments.deployments'}",:view => @view, :id => 'deployments', :count => @pool.deployments.count},
             #{:name => 'History',        :view => @view,         :id => 'history'},
             {:name => "#{t'properties'}", :view => 'properties', :id => 'properties'},
             {:name => "#{t'catalog_images'}", :view => 'images', :id => 'images'}
    ]
    if "images" == params[:details_tab]
      @map = @pool.provider_image_map
    end
    add_permissions_tab(@pool)

    details_tab_name = params[:details_tab].blank? ? 'deployments' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    @deployments = @pool.deployments if @details_tab[:id] == 'deployments'
    @view = @details_tab[:view]
    respond_to do |format|
      format.html { render :action => :show}
      format.js { render :partial => @view }
      format.json { render :json => @pool.as_json(:with_deployments => true) }
    end
  end

  def new
    require_privilege(Privilege::CREATE, Pool)
    @pool = Pool.new
    @quota = Quota.new
    respond_to do |format|
      format.html
      format.json { render :json => @pool }
      format.js { render :partial => 'new' }
    end
  end

  def create
    require_privilege(Privilege::CREATE, Pool)

    @pool = Pool.new(params[:pool])
    @pool.quota = @quota = Quota.new
    set_quota

    respond_to do |format|
      if @pool.save
        @pool.assign_owner_roles(current_user)
        flash[:notice] = t "pools.flash.notice.added"
        format.html { redirect_to :action => 'show', :id => @pool.id }
        # TODO - The new UI is almost certainly going to want a new partial for .js
        format.js { render :partial => 'show', :id => @pool.id }
        format.json { render :json => @pool, :status => :created }
      else
        flash.now[:warning] = t "pools.flash.warning.creation_failed"
        format.html { render :new }
        format.js { render :partial => 'new' }
        format.json { render :json => @pool.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota
    respond_to do |format|
      format.html
      format.js { render :partial => 'edit' }
      format.json { render :json => @pool }
    end
  end

  def update
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    set_quota
    @quota = @pool.quota

    respond_to do |format|
      if @pool.update_attributes(params[:pool])
        flash[:notice] = t "pools.flash.notice.updated"
        format.html { redirect_to :action => 'show', :id => @pool.id }
        format.js { render :partial => 'show', :id => @pool.id }
        format.json { render :json => @pool }
      else
        flash[:error] = t "pools.flash.error.not_updated"
        format.html { render :action => :edit }
        format.js { render :partial => 'edit', :id => @pool.id }
        format.json { render :json => @pool.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    destroyed = []
    failed = []
    error_messages = []
    Pool.find(ids_list('pools_selected')).each do |pool|
      if pool.id == MetadataObject.lookup("self_service_default_pool").id
        error_messages << t("pools.flash.error.default_pool_not_deleted")
      elsif check_privilege(Privilege::MODIFY, pool) && pool.destroyable?
        pool.destroy
        destroyed << pool.name
      else
        failed << pool.name
      end
    end
    flash[:success] = t('pools.flash.success.pool_deleted', :list => destroyed.to_sentence, :count => destroyed.size) if destroyed.present?
    flash[:error] = t('pools.flash.error.pool_not_deleted', :list => failed.to_sentence, :count => failed.size) if failed.present?
    respond_to do |format|
      # TODO - What is expected to be returned on an AJAX delete?
      format.html { redirect_to pools_url }
      format.js do
        load_pools
        render :partial => 'list'
      end
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  def multi_destroy
    destroyed = []
    failed = []
    error_messages = []
    Pool.find(params[:pools_selected]).each do |pool|
      # FIXME: remove this check when pools can be assigned to new users
      # default_pool cannot be deleted because metadata object has it tied
      # to id of 1 and deleting it prevents new users from being created
      if pool.id == MetadataObject.lookup("self_service_default_pool").id
        error_messages << t("pools.flash.error.default_pool_not_deleted")
      elsif check_privilege(Privilege::MODIFY, pool) && pool.destroyable?
        pool.destroy
        destroyed << pool.name
      else
        failed << pool.name
      end
    end

    unless destroyed.empty?
      flash[:notice] = t('pools.flash.success.pool_deleted', :count => destroyed.length, :list => destroyed.join(', '))
    end
    unless failed.empty?
      error_messages << t('pools.flash.error.pool_not_deleted', :count => failed.length, :list => failed.join(', '))
    end
    unless error_messages.empty?
      flash[:error] = error_messages.join('<br />')
    end
    respond_to do |format|
      format.html { redirect_to pools_url }
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  protected

  def set_params_and_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => '', :class => 'alert', :sortable => false },
      { :name => t("pools.index.pool_name"), :sort_attr => :name },
      { :name => t("deployments.deployments"), :class => 'center', :sortable => false },
      { :name => t("instances.instances"), :class => 'center', :sortable => false },
      { :name => t("pools.index.pending"), :class => 'center', :sortable => false },
      { :name => t("pools.index.failed"), :class => 'center', :sortable => false },
      { :name => t("quota_used"), :class => 'center', :sortable => false },
      { :name => t("pools.index.pool_family"), :sortable => false },

    ]
    @deployments_header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => '', :class => 'alert', :sortable => false },
      { :name => t("deployments.deployment_name"), :sortable => false },
      { :name => t("pools.index.deployed_on"), :sortable => false },
      { :name => t("deployables.index.base_deployable"), :sortable => false },
      { :name => t("deployables.index.state"), :sortable => false },
      { :name => t("instances.instances"), :class => 'center', :sortable => false },
      { :name => t("pools.pool"), :sortable => false },
      { :name => t("pools.index.owner"), :sortable => false },
      { :name => t("providers.provider"), :sortable => false }
    ]
  end

  def load_pools
    @pools = Pool.paginate(:include => [ :quota, :pool_family ],
      :page => params[:page] || 1,
      :order => (sort_column(Pool)+' '+ sort_direction)
    )
  end

  def load_instances
    # If state isn't specified at all, show only running instances.
    # (But if it's nil, we want to show all instances)
    params[:state] = 'running' unless params.keys.include?('state')
    conditions = params[:state].present? ? ['state=?', params[:state]] : ''
    @instances = @pool.instances.find(:all, :conditions => conditions)
  end

  def set_quota
    limit = if params.has_key? :quota and not params[:unlimited_quota]
              params[:quota][:maximum_running_instances]
            else
              nil
            end
    @pool.quota.set_maximum_running_instances(limit)
  end

  def statistics
    instances = Instance.list_for_user(current_user, Privilege::VIEW)
    pf_max_quotas = @user_pool_families.collect {|pf| pf.quota.maximum_running_instances}
    @failed_instances = instances.select {|instance| instance.state == Instance::STATE_CREATE_FAILED || instance.state == Instance::STATE_ERROR}
    @statistics = {
              :pools_in_use => @user_pools.collect { |pool| pool.instances.pending.count > 0 || pool.instances.deployed.count > 0 }.count,
              :deployments => Deployment.list_for_user(current_user, Privilege::VIEW).count,
              :instances => instances.count,
              :instances_pending => instances.select {|instance| instance.state == Instance::STATE_NEW || instance.state == Instance::STATE_PENDING}.count,
              :instances_failed => @failed_instances.count,
              :pf_available_quota => pf_max_quotas.compact.size != @user_pool_families.size ? nil :  @user_pool_families.collect{|pf| pf.quota.maximum_running_instances}.inject(0){|sum, n| sum + n},
              :pf_running_instances => @user_pool_families.collect{|pf| pf.quota.running_instances}.inject(0){|sum, n| sum + n},
              :pf_used_percentage => @user_pool_families.collect {|pf| pf.quota.percentage_used}.inject(0){|sum, n| sum + n}
              }
  end
end
