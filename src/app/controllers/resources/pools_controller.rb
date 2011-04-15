class Resources::PoolsController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pools, :only => [:show]

  def index
    @search_term = params[:q]
    if @search_term.blank?
      load_pools
      return
    end

    search = Pool.search() do
      keywords(params[:q])
    end
    @pools = search.results
  end

  def show
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::VIEW, @pool)
    @url_params = params.clone
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
    end
  end

  def new
    require_privilege(Privilege::CREATE, Pool)
    @pool = Pool.new
    @quota = Quota.new
  end

  def create
    require_privilege(Privilege::CREATE, Pool)

    @pool = Pool.new(params[:pool])
    @pool.quota = @quota = Quota.new

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @pool.quota.set_maximum_running_instances(limit)

    if @pool.save
      @pool.assign_owner_roles(current_user)
      flash[:notice] = "Pool added."
      redirect_to :action => 'show', :id => @pool.id
    else
      flash.now[:warning] = "Pool creation failed."
      render :new and return
    end
  end

  def edit
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota
  end

  def update
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
    @quota = @pool.quota

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @pool.quota.set_maximum_running_instances(limit)
    if @pool.update_attributes(params[:pool])
      flash[:notice] = "Pool updated."
      redirect_to :action => 'show', :id => @pool.id
    else
      flash[:error] = "Pool wasn't updated!"
      render :action => :edit
    end
  end

  def multi_destroy
    Pool.find(params[:pools_selected]).each do |pool|
      # FIXME: remove this check when pools can be assigned to new users
      # default_pool cannot be deleted because metadata object has it tied
      # to id of 1 and deleting it prevents new users from being created
      if pool.id == MetadataObject.lookup("self_service_default_pool").id
        flash[:notice] = "The default pool cannot be deleted"
      else
        pool.destroy if check_privilege(Privilege::MODIFY, pool)
      end
    end
    redirect_to resources_pools_url
  end

  protected

  def set_params_and_header
    @url_params = params.clone
    @header = [
      { :name => "Pool name", :sort_attr => :name },
      { :name => "Quota (Instances)", :sort_attr => "quotas.total_instances"},
      { :name => "% Quota used", :sortable => false },
      { :name => "Pool Family", :sort_attr => "pool_families.name" }
    ]
  end

  def load_pools
    @pools = Pool.paginate(:all, :include => [ :quota, :pool_family ],
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end
end
