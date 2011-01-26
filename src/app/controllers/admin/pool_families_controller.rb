class Admin::PoolFamiliesController < ApplicationController
  before_filter :require_user
  before_filter :load_pool_families, :only =>[:index,:show]

  def index
  end

  def new
    @pool_family = PoolFamily.new
  end

  def create
    @pool_family = PoolFamily.new(params[:pool_family])
    unless @pool_family.save
      flash.now[:warning] = "Pool family's creation failed."
      render :new and return
    else
      @pool_family.assign_owner_roles(current_user)
      flash[:notice] = "Pool family was added."
      redirect_to admin_pool_families_path
    end
  end

  def edit
    @pool_family = PoolFamily.find(params[:id])
  end

  def update
    @pool_family = PoolFamily.find(params[:id])
    unless @pool_family.update_attributes(params[:pool_family])
      flash[:error] = "Pool Family wasn't updated!"
      render :action => 'edit' and return
    else
      flash[:notice] = "Pool Family was updated!"
      redirect_to admin_pool_families_path
    end
  end

  def show
    @pool_family = PoolFamily.find(params[:id])
    @url_params = params.clone
    @tab_captions = ['Properties', 'History', 'Permissions', 'Provider Accounts', 'Pools']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :parial => @details_tab and return
      end
      format.html { render :show }
    end
  end

  def multi_destroy
    PoolFamily.destroy(params[:pool_family_selected])
    redirect_to admin_pool_families_path
  end

  protected

  def load_pool_families
    @header = [{ :name => "Name", :sort_attr => :name},
               { :name => "Quota limit", :sort_attr => :name},
               { :name => "Quota currently in use", :sort_attr => :name},
    ]
    @pool_families = PoolFamily.paginate(:all,
                                         :page => params[:page] || 1,
                                         :order => ( params[:order_field] || 'name' ) + ' ' + (params[:order_dir] || 'asc')
                                        )
    @url_params = params.clone
  end
end
