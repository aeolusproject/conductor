class Resources::PoolsController < ApplicationController
  before_filter :require_user
  before_filter :load_pools, :only => [:index, :show]

  def index
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

  def edit
    render :text => "Edit Pool #{params[:id]}"
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
    @pool.zone = Zone.default
    if @pool.save
      flash[:notice] = "Pool added."
      redirect_to :action => 'show', :id => @pool.id
    else
      render :action => :new
    end
  end

  protected

  def load_pools
    @header = [
      { :name => "Pool name", :sort_attr => :name },
      { :name => "% Quota used", :sortable => false },
      { :name => "Quota (Instances)", :sort_attr => "quotas.total_instances"},
      { :name => "Zone", :sort_attr => "zones.name" }
    ]
    @pools = Pool.paginate(:all, :include => [ :quota, :zone ],
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
    @url_params = params.clone
  end
end
