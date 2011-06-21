class ProviderAccountsController < ApplicationController
  before_filter :require_user
  before_filter :load_accounts, :only => [:index,:show]
  before_filter :set_view_vars, :only => [:index,:show]

  def top_section
    :administer
  end

  def index
    clear_breadcrumbs
    save_breadcrumb(provider_accounts_path)
    # TODO: this is temporary solution how to combine search and permissions
    # filtering
    @search_term = params[:q]
    unless @search_term.blank?
      search = ProviderAccount.search do
        keywords(params[:q])
      end
      @accounts &= search.results
    end

    respond_to do |format|
      format.html
      format.xml { render :partial => 'list.xml' }
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

    save_breadcrumb(provider_account_path(@account), @account.name)

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

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)

    if @provider_account.invalid? || !@provider_account.valid_credentials?
      flash[:error] = "Credentials are invalid!"
      render :action => 'new' and return
    end

    @provider_account.pool_families << PoolFamily.default
    @provider_account.save!
    @provider_account.assign_owner_roles(current_user)
    if @provider_account.populate_realms
      flash[:notice] = "Provider account added."
    end
    redirect_to provider_account_path(@provider_account)
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

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)
    if @provider_account.update_attributes(params[:provider_account])
      flash[:notice] = "Provider Account updated!"
      redirect_to provider_account_path(@provider_account)
    else
      flash[:error] = "Provider Account wasn't updated!"
      render :action => :edit
    end
  end

  def destroy
    require_privilege(Privilege::MODIFY, @provider_account)
    if ProviderAccount.destroy(params[:id])
      flash[:notice] = "Provider account was deleted!"
    else
      flash[:error] = "Provider account was not deleted!"
    end
    redirect_to provider_accounts_path
  end

  def multi_destroy
    if params[:accounts_selected].blank?
      flash[:warning] = "You must select some accounts first."
      redirect_to provider_accounts_url and return
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
    redirect_to provider_accounts_url
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
    #FIXME need to include atributes from credentials, credential_definitions and provider_type in load_accounts query to make it work
    @header = [
      { :name => "Name", :sortable => false },
      { :name => "Username", :sortable => false},
      { :name => "Provider Type", :sortable => false }
    ]
    @url_params = params
  end

  def load_accounts
    @accounts = ProviderAccount.list_for_user(current_user, Privilege::VIEW)
  end
end
