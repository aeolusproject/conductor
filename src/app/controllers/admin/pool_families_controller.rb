class Admin::PoolFamiliesController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pool_families, :only =>[:show]
  before_filter :load_tab_captions_and_details_tab, :only => [:show]

  def index
    @search_term = params[:q]
    if @search_term.blank?
      load_pool_families
      return
    end

    search = PoolFamily.search() do
      keywords(params[:q])
    end
    @pool_families = search.results
  end

  def new
    @pool_family = PoolFamily.new(:quota => Quota.new)
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
    @pool_family.quota ||= Quota.new
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

    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :show }
    end
  end

  def add_provider_account
    @pool_family = PoolFamily.find(params[:id])
    @provider_account = ProviderAccount.find(params[:provider_account_id])

    @pool_family.provider_accounts << @provider_account
    flash[:notice] = "Provider Account has been added"
    redirect_to admin_pool_family_path(@pool_family, :details_tab => 'provider_accounts')
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    PoolFamily.find(params[:pool_family_selected]).each do |pool_family|
      if pool_family.destroy
        deleted << pool_family.name
      else
        not_deleted << pool_family.name
      end
    end
    if deleted.size > 0
      flash[:notice] = t 'pool_families.index.deleted', :list => deleted.join(', ')
    end
    if not_deleted.size > 0
      flash[:error] = t 'pool_families.index.not_deleted', :list => not_deleted.join(', ')
    end
    redirect_to admin_pool_families_path
  end

  def multi_destroy_provider_accounts
    @pool_family = PoolFamily.find(params[:pool_family_id])

    ProviderAccount.find(params[:provider_account_selected]).each do |provider_account|
      @pool_family.provider_accounts.delete provider_account
    end

    redirect_to admin_pool_family_path(@pool_family, :details_tab => 'provider_accounts')
  end

  protected

  def load_tab_captions_and_details_tab
    @tab_captions = ['Properties', 'History', 'Permissions', 'Provider Accounts', 'Pools']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    @provider_accounts_header = [{ :name => "Provider Account", :sort_attr => :name}]
  end

  def set_params_and_header
    @url_params = params.clone
    @header = [{ :name => "Name", :sort_attr => :name},
               { :name => "Quota limit", :sort_attr => :name},
               { :name => "Quota currently in use", :sort_attr => :name},
    ]
  end

  def load_pool_families
    @pool_families = PoolFamily.paginate(:all,
                                         :page => params[:page] || 1,
                                         :order => ( params[:order_field] || 'name' ) + ' ' + (params[:order_dir] || 'asc')
                                        )
  end
end
