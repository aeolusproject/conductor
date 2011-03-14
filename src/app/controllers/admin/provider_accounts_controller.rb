class Admin::ProviderAccountsController < ApplicationController
  before_filter :require_user
  before_filter :load_accounts, :only => :show
  before_filter :set_view_vars, :only => [:index,:show]

  def index
    @search_term = params[:q]
    if @search_term.blank?
      load_accounts
    else
      search = ProviderAccount.search do
        keywords(params[:q])
      end
      @accounts = search.results
    end
  end

  def show
    @tab_captions = ['Properties', 'Credentials', 'History', 'Permissions']
    @account = ProviderAccount.find(params[:id])
    require_privilege(Privilege::VIEW, @account)
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    if params.delete :test_account
      test_account(@account)
      render :action => 'show' and return
    end

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
    @provider_account = ProviderAccount.new
    @quota = Quota.new
    @providers = Provider.all
    if @providers.empty?
      flash[:error] = "You don't have any provider yet. Please create one!"
    else
    @selected_provider = @providers.first unless @providers.blank?
    end
  end

  def create
    @selected_provider = @provider = Provider.find(params[:provider_account][:provider_id])
    require_privilege(Privilege::CREATE, ProviderAccount, @provider)

    @providers = Provider.all
    @provider_account = ProviderAccount.new(params[:provider_account])
    @provider_account.provider = @provider
    @provider_account.quota = @quota = Quota.new

    if params.delete :test_account
      test_account(@provider_account)
      render :action => 'new' and return
    end

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)

    if @provider_account.invalid?
      if not @provider_account.valid_credentials?
        flash.now[:error] = "The entered credential information is incorrect"
      elsif @provider_account.errors.on(:username)
        flash.now[:error] = "The access key '#{params[:provider_account][:username]}' has already been taken."
      else
        flash.now[:error] = "You must fill in all the required fields"
      end
      render :action => 'new' and return
    end

    @provider_account.pool_families << PoolFamily.default
    @provider_account.save!
    @provider_account.assign_owner_roles(current_user)
    if @provider_account.populate_realms
      flash[:notice] = "Provider account added."
    end
    redirect_to admin_provider_account_path(@provider_account)
    kick_condor
  end

  def edit
    @provider_account = ProviderAccount.find(params[:id])
    @selected_provider = @provider_account.provider
    @quota = @provider_account.quota
    @providers = Provider.find(:all)
    require_privilege(Privilege::MODIFY,@provider_account)
  end

  def update
    @provider_account = ProviderAccount.find(params[:id])
    @selected_provider = @provider = @provider_account.provider
    require_privilege(Privilege::MODIFY, @provider)
    require_privilege(Privilege::MODIFY,@provider_account)
    @quota = @provider_account.quota
    @providers = Provider.find(:all)

    if params.delete :test_account
      test_account(@provider_account)
      render :action => 'edit' and return
    end

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)
    if @provider_account.update_attributes(params[:provider_account])
      flash[:notice] = "Provider Account updated!"
      redirect_to admin_provider_account_path(@provider_account)
    else
      flash[:error] = "Provider Account wasn't updated!"
      render :action => :edit
    end
  end

  def multi_destroy
    if params[:accounts_selected].blank?
      flash[:notice] = "You must select some accounts first."
      redirect_to admin_provider_accounts_url and return
    end

    succeeded = []
    failed = []
    ProviderAccount.find(params[:accounts_selected]).each do |account|
      if check_privilege(Privilege::MODIFY, account) && account.destroyable?
        account.destroy
        succeeded << account.label
      else
        failed << account.label
      end
    end

    unless succeeded.empty?
      flash[:notice] = t 'provider_accounts.index.account_deleted', :count => succeeded.length, :list => succeeded.join(', ')
    end
    unless failed.empty?
      flash[:error] = t 'provider_accounts.index.account_not_deleted', :count => failed.length, :list => failed.join(', ')
    end
    redirect_to admin_provider_accounts_url
  end

  def set_selected_provider
    @quota = Quota.new
    @provider_account = ProviderAccount.new
    respond_to do |format|
      format.js {
        @providers = Provider.find(:all)
        @selected_provider = Provider.find(params[:provider_account][:provider_id])
        render :partial => 'provider_selection'
      }
      format.html {
        @providers = Provider.find(:all)
        @selected_provider = Provider.find(params[:provider_account][:provider_id])
        render :action => 'new', :layout => true
      }
    end
  end

  protected

  def test_account(account)
    if account.valid_credentials?
      flash.now[:notice] = "Test Connection Success: Valid Account Details"
    else
      flash.now[:error] = "Test Connection Failed: Invalid Account Details"
    end
  rescue
    flash.now[:error] = "Test Connection Failed: Could not connect to provider"
  end

  def set_view_vars
    @header = [
      { :name => "Name", :sort_attr => :name },
      { :name => "Username", :sort_attr => :username},
      { :name => "Provider Type", :sort_attr => :provider_type }
    ]
    @url_params = params
  end

  def load_accounts
    @accounts = ProviderAccount.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'label') +' '+ (params[:order_dir] || 'asc')
    )
  end
end
