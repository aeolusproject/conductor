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

class PoolsController < ApplicationController
  include QuotaAware
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pools, :only => [:show]
  before_filter ResourceLinkFilter.new({ :pool => :pool_family }),
                :only => [:create, :update]

  viewstate :index do |default|
    default.merge!({
      :view => 'pretty',
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

    # This is primarily relevant to filter_view, but we check @details_tab in other places:
    @tabs = [{:name => "#{t'pools.pools'}", :view => 'list', :id => 'pools', :pretty_view_toggle => 'enabled'},
             {:name => "#{t'deployments.deployments'}", :view => 'deployments/list', :id => 'deployments', :pretty_view_toggle => 'enabled'},
             {:name => "#{t'instances.instances.other'}", :view => 'instances/list', :id => 'instances', :pretty_view_toggle => 'enabled'},
    ]
    details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase

    @user_pools = Pool.list_for_user(current_session, current_user,
                                     Privilege::CREATE, Deployment)

    if filter_view?
      case @details_tab[:id]
      when 'pools'
        @pools = paginate_collection(
          Pool.includes(:deployments, :instances).
            apply_filters(:preset_filter_id => params[:pools_preset_filter],
                          :search_filter => params[:pools_search]).
            list_for_user(current_session, current_user, Privilege::VIEW).
            list(sort_column(Pool), sort_direction),
          params[:page], PER_PAGE)
      when 'instances'
        params[:instances_preset_filter] = "" unless params[:instances_preset_filter]
        @instances = paginate_collection(
          Instance.includes({:provider_account => :provider}).
            apply_filters(:preset_filter_id => params[:instances_preset_filter],
                          :search_filter => params[:instances_search]).
            list_for_user(current_session, current_user, Privilege::VIEW).
            list(sort_column(Instance), sort_direction),
          params[:page], PER_PAGE)
      when 'deployments'
        @deployments = paginate_collection(
          Deployment.includes(:pool, :instances).
            apply_filters(:preset_filter_id =>
                            params[:deployments_preset_filter],
                          :search_filter => params[:deployments_search]).
            list_for_user(current_session, current_user, Privilege::VIEW).
            list(sort_column(Deployment), sort_direction),
          params[:page], PER_PAGE)
      end
    else
      @pools = paginate_collection(
        Pool.includes(:quota, :catalogs).
          list_for_user(current_session, current_user, Privilege::VIEW).
          list(sort_column(Pool), sort_direction),
        params[:page], PER_PAGE)
    end

    user_statistics
    respond_to do |format|
      format.html { @view = filter_view? ? 'layouts/tabpanel' : 'pretty_list' }
      format.js do
        if filter_view?
          render :partial => params[:only_tab] == "true" ? @details_tab[:view] : 'layouts/tabpanel'
        else
          render :partial => 'pretty_list'
        end
      end
      format.json do
        case @details_tab[:id]
        when 'pools'
          json = @pools.map{ |pool| view_context.pool_for_mustache(pool) }
        when 'instances'
          json = @instances.
            map{ |instance| view_context.instance_for_mustache(instance) }
        when 'deployments'
          json = @deployments.
            map{ |deployment| view_context.deployment_for_mustache(deployment) }
        end
        render :json => {
          :collection => json,
          :user_info => view_context.user_info_for_mustache
        }
      end
      format.xml do
        render :partial => 'list.xml'
      end
    end
  end

  def show
    @pool = Pool.find(params[:id])
    @title = @pool.name
    save_breadcrumb(pool_path(@pool, :viewstate => viewstate_id), @pool.name)
    require_privilege(Privilege::VIEW, @pool)
    @catalogs = @pool.catalogs.list_for_user(current_session, current_user,
                                             Privilege::VIEW)
    @statistics = @pool.statistics(current_session, current_user)

    if params[:details_tab]
      case params[:details_tab]
        when 'images'
          # this case covers fetching of unique images and constructing
          # collection for filter table
          # 19sept2012 -- FIXME - These aren't really the correct translation names, but
          #  this patch is after string freeze so I'm confined to using them. --mawagner
          @header = [{:name => t("pools.images.catalog")}, {:name => t("catalog_entries.index.catalog_entry")},
                     {:name => t("logs.index.image")}, {:name => t("images.show.providers_image_id")}]
          @catalog_images = @pool.catalog_images_collection(@catalogs)
        when 'deployments'
          @view = filter_view? ? 'deployments/list' : 'deployments/pretty_view'
      end
    else
      @view = filter_view? ? 'deployments/list' : 'deployments/pretty_view'
    end

    #TODO add links to real data for history,properties,permissions
    @tabs = [{:name => "#{t'deployments.deployments'}",:view => @view, :id => 'deployments', :count => @pool.deployments.count, :pretty_view_toggle => 'enabled'},
             #{:name => 'History',        :view => @view,         :id => 'history'},
             {:name => "#{t'properties'}", :view => 'properties', :id => 'properties'},
             {:name => "#{t'catalog_images'}", :view => 'images', :id => 'images'}
    ]
    add_permissions_tab(@pool)

    details_tab_name = params[:details_tab].blank? ? 'deployments' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    if @details_tab[:id] == 'deployments'
      @deployments = paginate_collection(
        @pool.deployments.includes(:owner, :pool, :instances, :events).
          apply_filters(:preset_filter_id => params[:deployments_preset_filter],
                        :search_filter => params[:deployments_search]).
          list_for_user(current_session, current_user, Privilege::VIEW),
        params[:page], PER_PAGE)
    end
    @view = @details_tab[:view]
    respond_to do |format|
      format.html { render :action => :show}
      format.js { render :partial => @view }
      format.json do
        deployments = paginate_collection(
            @pool.deployments.list_for_user(current_session, current_user,
                                            Privilege::VIEW),
            params[:page], PER_PAGE).
          map{ |deployment| view_context.deployment_for_mustache(deployment) }
        render :json => @pool.as_json.merge({:deployments => deployments})
      end
      format.xml { render :show, :locals => { :pool => @pool, :catalogs => @catalogs } }
    end
  end

  def new
    @title = t('pools.create_new_pool')
    @pool = Pool.new
    @pool.pool_family = PoolFamily.find(params[:pool_family_id]) unless params[:pool_family_id].blank?
    require_privilege(Privilege::CREATE, Pool, @pool.pool_family)
    @quota = Quota.new
    @pool_families = PoolFamily.list_for_user(current_session, current_user,
                                              Privilege::CREATE, Pool)
    respond_to do |format|
      format.html
      format.json { render :json => @pool }
      format.js { render :partial => 'new' }
    end
  end

  def create
    @title = t('pools.create_new_pool')
    set_quota_param(:pool)
    @pool = Pool.new(params[:pool])
    require_privilege(Privilege::CREATE, Pool, @pool.pool_family)
    @catalogs = @pool.catalogs.list_for_user(current_session, current_user,
                                             Privilege::VIEW)
    @pool.quota = @quota = Quota.new
    set_quota(@pool)

    respond_to do |format|
      if @pool.save
        @pool.assign_owner_roles(current_user)
        flash[:notice] = t "pools.flash.notice.added"
        format.html { redirect_to pools_path }
        format.json { render :json => @pool, :status => :created }
        format.xml {render :show,
                           :status => :created,
                           :locals => { :pool => @pool, :catalogs => @catalogs }
        }
      else
        flash.now[:warning] = t "pools.flash.warning.creation_failed"
        format.html { render :new }
        format.js { render :partial => 'new' }
        format.json { render :json => @pool.errors, :status => :unprocessable_entity }
        format.xml { render :template => 'api/validation_error',
                            :locals => { :errors => @pool.errors },
                            :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @pool = Pool.find(params[:id])
    @title = t('pools.edit_pool', :pool => @pool.name)
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota
    respond_to do |format|
      format.html
      format.js { render :partial => 'edit' }
      format.json { render :json => @pool }
    end
  end

  def update
    set_quota_param(:pool)
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @catalogs = @pool.catalogs.list_for_user(current_session, current_user,
                                             Privilege::VIEW)
    set_quota(@pool)
    @quota = @pool.quota

    respond_to do |format|
      if @pool.update_attributes(params[:pool])
        flash[:notice] = t "pools.flash.notice.updated"
        format.html { redirect_to :action => 'show', :id => @pool.id }
        format.js { render :partial => 'show', :id => @pool.id }
        format.json { render :json => @pool }
        format.xml {render :show, :locals => { :pool => @pool, :catalogs => @catalogs } }
      else
        flash[:error] = t "pools.flash.error.not_updated"
        format.html { render :action => :edit }
        format.js { render :partial => 'edit', :id => @pool.id }
        format.json { render :json => @pool.errors, :status => :unprocessable_entity }
        format.xml { render :template => 'api/validation_error',
                            :locals => { :errors => @pool.errors },
                            :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    destroyed = []
    failed = []
    permission_failed = []
    error_messages = []
    pool_id = nil
    Pool.find(ids_list(['pools_selected'])).each do |pool|
      pool_id = pool.id
      if pool.id == MetadataObject.lookup("self_service_default_pool").id
        error_messages << t("pools.flash.error.default_pool_not_deleted")
      elsif !check_privilege(Privilege::MODIFY, pool)
        permission_failed << pool.name
      elsif !pool.destroyable?
        failed << pool.name
      else
        pool.destroy
        destroyed << pool.name
      end
    end

    flash[:success] = t('pools.flash.success.pool_deleted', :list => destroyed.to_sentence, :count => destroyed.size) if destroyed.present?
    if permission_failed.any?
      flash[:error] = t('application_controller.permission_denied')
    elsif failed.any?
      flash[:error] = t('pools.flash.error.pool_not_deleted', :list => failed.to_sentence, :count => failed.size) if failed.present?
    end
    flash[:warning] = error_messages if error_messages.present?
    respond_to do |format|
      # TODO - What is expected to be returned on an AJAX delete?
      format.html { redirect_to pools_url }
      format.js do
        load_pools
        render :partial => 'list'
      end
      format.json { render :json => {:success => destroyed, :errors => failed} }
      format.xml {
        if failed.present?
          raise(Aeolus::Conductor::API::Error.new(500, flash[:error]))
        elsif error_messages.present?
          raise(Aeolus::Conductor::API::Error.new(500, error_messages.join(' ')))
        else
          render :nothing => true, :status => :no_content
        end
      }
    end
  end

  def multi_destroy
    destroyed = []
    failed = []
    permission_failed = []
    error_messages = []
    Pool.find(params[:pools_selected]).each do |pool|
      # FIXME: remove this check when pools can be assigned to new users
      # default_pool cannot be deleted because metadata object has it tied
      # to id of 1 and deleting it prevents new users from being created
      if pool.id == MetadataObject.lookup("self_service_default_pool").id
        error_messages << t("pools.flash.error.default_pool_not_deleted")
      elsif !check_privilege(Privilege::MODIFY, pool)
        permission_failed << pool.name
      elsif !pool.destroyable?
        failed << pool.name
      else
        pool.destroy
        destroyed << pool.name
      end
    end

    unless destroyed.empty?
      flash[:notice] = t('pools.flash.success.pool_deleted', :count => destroyed.length, :list => destroyed.join(', '))
    end
    unless failed.empty?
      error_messages << t('pools.flash.error.pool_not_deleted', :count => failed.length, :list => failed.join(', '))
    end
    unless permission_failed.empty?
      error_messages << t('application_controller.permission_denied')
    end
    unless error_messages.empty?
      flash[:error] = error_messages
    end
    respond_to do |format|
      format.html { redirect_to pools_url }
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  def filter
    redirect_to_original({"pools_preset_filter" => params[:pools_preset_filter], "pools_search" => params[:pools_search]})
  end

  protected

  def set_params_and_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => '', :class => 'alert', :sortable => false },
      { :name => t("pools.index.pool_name"), :sort_attr => :name },
      { :name => t("deployments.deployments"), :class => 'center', :sortable => false },
      { :name => t("instances.instances.other"), :class => 'center', :sortable => false },
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
      { :name => t("instances.instances.other"), :class => 'center', :sortable => false },
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
    @instances = @pool.instances.list_for_user(current_session, current_user,
                                               Privilege::VIEW).
      where(conditions)
  end

  def user_statistics
    failed_instances = current_user.owned_instances.failed
    @user_statistics = {
              :instances_failed => failed_instances,
              :instances_failed_count => failed_instances.count,
              :user_available_quota => current_user.quota.maximum_running_instances,
              }
  end
end
