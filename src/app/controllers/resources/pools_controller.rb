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
    require_privilege(Privilege::POOL_MODIFY)
    @pool = Pool.new
  end

  def create
    require_privilege(Privilege::POOL_MODIFY)

    @pool = Pool.new(params[:pool])
    quota = Quota.new
    quota.save!

    @pool.quota_id = quota.id
    @pool.pool_family = PoolFamily.default
    if @pool.save
      flash[:notice] = "Pool added."
      redirect_to :action => 'show', :id => @pool.id
    else
      render :action => :new
    end
  end

  def edit
    require_privilege(Privilege::POOL_MODIFY)

    @pool = Pool.find(params[:id])
  end

  def update
    require_privilege(Privilege::POOL_MODIFY)

    @pool = Pool.find(params[:id])
    if @pool.update_attributes(params[:pool])
      flash[:notice] = "Pool updated."
      redirect_to :action => 'show', :id => @pool.id
    else
      render :action => :edit
    end
  end

  def multi_destroy
    Pool.destroy(params[:pools_selected])
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
