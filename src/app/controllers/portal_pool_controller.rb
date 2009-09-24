class PortalPoolController < ApplicationController
  before_filter :require_user

  def index
    render :action => 'new'
  end

  def show
    @instances = Instance.find(:all, :conditions => {:portal_pool_id => params[:id]})
    #FIXME: clean this up, many error cases here
    @pool = PortalPool.find(params[:id])
    @provider = @pool.cloud_account.provider
  end

  def new
    @portal_pool = PortalPool.new
    @account = CloudAccount.new
    @account.provider_id = params[:provider]
  end

  def create
    @account = CloudAccount.find_or_create(params[:account])
    #FIXME: This should probably be in a transaction
    if @account.save
      @portal_pool = @account.portal_pools.build(params[:portal_pool])
      if @portal_pool.save && @portal_pool.populate_realms_and_images
        flash[:notice] = "Pool added."
        redirect_to :action => 'show', :id => @portal_pool.id
      else
        render :action => 'new'
      end
    else
      render :action => 'new'
    end
  end

  def delete
  end
end
