class PoolsController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pools, :only => [:show]

  def index
    @search_term = params[:q]
    if @search_term.blank?
      load_pools
    else
      @pools = Pool.search() { keywords(params[:q]) }.results
    end
    respond_to do |format|
      format.html
      format.json { render :json => @pools }
    end
  end

  def show
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::VIEW, @pool)
    @url_params = params.clone
    load_instances
    @tab_captions = ['Properties', 'Deployments', 'Instances', 'History', 'Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
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
        format.json { render :json => @pool, :status => :created }
      else
        flash.now[:warning] = "Pool creation failed."
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
        format.html { redirect_to :action => 'show', :id => @pool.id }
        format.json { render :json => @pool }
      else
        flash[:error] = "Pool wasn't updated!"
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
end
