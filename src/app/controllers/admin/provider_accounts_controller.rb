class Admin::ProviderAccountsController < ApplicationController
  before_filter :require_user
  before_filter :load_accounts, :only => [:index, :show]

  def index
  end

  def show
    @tab_captions = ['Properties', 'Credentials', 'History', 'Permissions']
    @account = CloudAccount.find(params[:id])
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
    @cloud_account = CloudAccount.new
    @quota = Quota.new
    @providers = Provider.all
  end

  def create
    @provider = Provider.find(params[:provider_id])
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)

    @providers = Provider.all
    @cloud_account = CloudAccount.new(params[:cloud_account])
    @cloud_account.provider = @provider
    @cloud_account.quota = @quota = Quota.new

    if params.delete :test_account
      test_account(@cloud_account)
      render :action => 'new' and return
    end

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @cloud_account.quota.set_maximum_running_instances(limit)

    if @cloud_account.invalid?
      if not @cloud_account.valid_credentials?
        flash.now[:error] = "The entered credential information is incorrect"
      elsif @cloud_account.errors.on(:username)
        flash.now[:error] = "The access key '#{params[:cloud_account][:username]}' has already been taken."
      else
        flash.now[:error] = "You must fill in all the required fields"
      end
      render :action => 'new' and return
    end

    @cloud_account.zones << Zone.default
    @cloud_account.save!
    if @cloud_account.populate_realms
      flash[:notice] = "Provider account added."
    end
    redirect_to admin_provider_account_path(@cloud_account)
    kick_condor
  end

  def edit
    @cloud_account = CloudAccount.find(params[:id])
    @quota = @cloud_account.quota
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
  end

  def update
    @cloud_account = CloudAccount.find(params[:id])
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)
    @quota = @cloud_account.quota

    if params.delete :test_account
      test_account(@cloud_account)
      render :action => 'edit' and return
    end

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @cloud_account.quota.set_maximum_running_instances(limit)
    if @cloud_account.update_attributes(params[:cloud_account])
      flash[:notice] = "Cloud Account updated!"
      redirect_to admin_provider_account_path(@cloud_account)
    else
      render :action => :edit
    end
  end

  def multi_destroy
    if (not params[:accounts_selected]) or (params[:accounts_selected].length == 0)
      flash[:notice] = "You must select some accounts first."
    else
      CloudAccount.destroy(params[:accounts_selected])
    end
    redirect_to admin_provider_accounts_url
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

  def load_accounts
    @header = [
      { :name => "Name", :sort_attr => :name },
      { :name => "Username", :sort_attr => :username},
    ]
    @accounts = CloudAccount.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'label') +' '+ (params[:order_dir] || 'asc')
    )
    @url_params = params
  end
end
