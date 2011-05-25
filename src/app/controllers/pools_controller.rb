class PoolsController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pools, :only => [:show]
  layout 'application'

  viewstate :index do |default|
    default.merge!({
      :pretty_view => true,
      :order_field => 'name',
      :order_dir => 'asc',
      :page => 1
    })
  end

  def index
    save_breadcrumb(pools_path(:viewstate => @viewstate ? @viewstate.id : nil))

    @user_pools = Pool.list_for_user(current_user, Privilege::VIEW)
    if filter_view?
      @tabs = [{:name => 'Pools', :view => 'list', :id => 'pools'},
               {:name => 'Deployments', :view => 'deployments/list', :id => 'deployments'},
               {:name => 'Instances', :view => 'instances/list', :id => 'instances'},
      ]
      details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
      @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
      case @details_tab[:id]
      when 'pools'
        @pools = Pool.list_or_search(params[:q], params[:order_field],params[:order_dir])
      when 'instances'
        @instances = Instance.list_or_search(params[:q], params[:order_field],params[:order_dir])
      when 'deployments'
        @deployments = Deployment.list_or_search(params[:q], params[:order_field],params[:order_dir])
      end
    else
      @pools = Pool.list_or_search(params[:q], params[:order_field],params[:order_dir])
    end
    statistics
    respond_to do |format|
      format.js { if filter_view?
                    render :partial => params[:only_tab] == "true" ? @details_tab[:view] : 'layouts/tabpanel'
                  else
                    render :partial => 'pretty_list'
                  end }
      format.html
      format.json { render :json => @pools }
    end
  end

  def show
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::VIEW, @pool)
    save_breadcrumb(pool_path(@pool), @pool.name)
    @statistics = @pool.statistics
    @view = params[:view] == 'filter' ? 'deployments/filter_view' : 'deployments/pretty_view'
    respond_to do |format|
      format.js { render :partial => @view, :locals => {:deployments => @pool.deployments} }
      format.html { render :action => :show}
      format.json { render :json => @pool }
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

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @pool.quota.set_maximum_running_instances(limit)

    respond_to do |format|
      if @pool.save
        @pool.assign_owner_roles(current_user)
        flash[:notice] = "Pool added."
        format.html { redirect_to :action => 'show', :id => @pool.id }
        # TODO - The new UI is almost certainly going to want a new partial for .js
        format.js { render :partial => 'show', :id => @pool.id }
        format.json { render :json => @pool, :status => :created }
      else
        flash.now[:warning] = "Pool creation failed."
        format.js { render :partial => 'new' }
        format.html { render :new }
        format.json { render :json => @pool.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota
    respond_to do |format|
      format.js { render :partial => 'edit' }
      format.html
      format.json { render :json => @pool }
    end
  end

  def update
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @pool.quota.set_maximum_running_instances(limit)
    respond_to do |format|
      if @pool.update_attributes(params[:pool])
        flash[:notice] = "Pool updated."
        format.js { render :partial => 'show', :id => @pool.id }
        format.html { redirect_to :action => 'show', :id => @pool.id }
        format.json { render :json => @pool }
      else
        flash[:error] = "Pool wasn't updated!"
        format.js { render :partial => 'edit', :id => @pool.id }
        format.html { render :action => :edit }
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
        error_messages << "The default pool cannot be deleted"
      elsif check_privilege(Privilege::MODIFY, pool) && pool.destroyable?
        pool.destroy
        destroyed << pool.name
      else
        failed << pool.name
      end
    end
    flash[:success] = t('pools.index.pool_deleted', :list => destroyed.to_sentence, :count => destroyed.size) if destroyed.present?
    flash[:error] = t('pools.index.pool_not_deleted', :list => failed.to_sentence, :count => failed.size) if failed.present?
    respond_to do |format|
      # TODO - What is expected to be returned on an AJAX delete?
      format.js do
        load_pools
        render :partial => 'list'
      end
      format.html { redirect_to pools_url }
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
        error_messages << "The default pool cannot be deleted"
      elsif check_privilege(Privilege::MODIFY, pool) && pool.destroyable?
        pool.destroy
        destroyed << pool.name
      else
        failed << pool.name
      end
    end

    unless destroyed.empty?
      flash[:notice] = t('pools.index.pool_deleted', :count => destroyed.length, :list => destroyed.join(', '))
    end
    unless failed.empty?
      error_messages << t('pools.index.pool_not_deleted', :count => failed.length, :list => failed.join(', '))
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
    @url_params = params.clone
    @header = [
      { :name => "Pool name", :sort_attr => :name },
      { :name => "Quota (Instances)", :sort_attr => "quotas.total_instances"},
      { :name => "% Quota used", :sortable => false },
      { :name => "Pool Family", :sort_attr => "pool_families.name" },
      { :name => "Enabled", :sort_attr => :enabled }
    ]
    @deployments_header = [
      { :name => "Deployment Name", :sort_attr => :name },
      { :name => "Base Deployable", :sort_attr => 'deployable.name' },
      { :name => "Uptime", :sort_attr => :created_at },
      { :name => "Instances", :sort_attr => 'instances.count' },
      { :name => "Provider", :sort_attr => :provider }
    ]
  end

  def load_pools
    @pools = Pool.paginate(:all, :include => [ :quota, :pool_family ],
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

  def load_instances
    # If state isn't specified at all, show only running instances.
    # (But if it's nil, we want to show all instances)
    params[:state] = 'running' unless params.keys.include?('state')
    conditions = params[:state].present? ? ['state=?', params[:state]] : ''
    @instances = @pool.instances.find(:all, :conditions => conditions)
  end

  def statistics
    instances = Instance.list_for_user(current_user, Privilege::VIEW)
    @failed_instances = instances.select {|instance| instance.state == Instance::STATE_CREATE_FAILED || instance.state == Instance::STATE_ERROR}
    @statistics = {
              :pools_in_use => @user_pools.collect { |pool| pool.instances.pending.count > 0 || pool.instances.deployed.count > 0 }.count,
              :deployments => Deployment.list_for_user(current_user, Privilege::VIEW).count,
              :instances => instances.count,
              :instances_pending => instances.select {|instance| instance.state == Instance::STATE_NEW || instance.state == Instance::STATE_PENDING}.count,
              :instances_failed => @failed_instances.count
              }
  end
end
