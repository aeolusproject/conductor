#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

class ProviderAccountsController < ApplicationController
  include QuotaAware
  before_filter :require_user
  before_filter :load_provider, :only => [:index,:update]
  before_filter :load_accounts, :only => [:index,:show]
  before_filter ResourceLinkFilter.new({ :provider_account => :provider }),
                :only => [:create, :update]

  def index
    clear_breadcrumbs
    save_breadcrumb(provider_accounts_path)

    respond_to do |format|
      #xml list of provider_accounts for aeolus-image, aeolus-image could work with prov. accounts list for givent provider
      #to resemble html views logic, so this route could be removed (provider_accounts could be user only as nested resource)
      #format.xml { render :text => ProviderAccount.xml_export(@provider_accounts) }
      format.xml { render :partial => 'list.xml', :locals => { :provider_accounts => @provider_accounts, :with_credentials => false, :with_quota => false, :minimal => false } }
    end
  end

  def show
    @tab_captions = [_('Properties'), _('Credentials'), _('History'), _('Permissions')]
    @provider_account = ProviderAccount.find(params[:id])
    @title = _('Account: %s') % @provider_account.name
    @provider = Provider.find_by_id(params[:provider_id])
    @realms = @provider_account.provider_realms.
                                apply_filters(:preset_filter_id => params[:provider_realms_preset_filter],
                                              :search_filter => params[:provider_realms_search])
    @account_id = @provider_account.credentials_hash['account_id']
    require_privilege(Privilege::VIEW, @provider_account)
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    @details_tab = 'properties' unless ['properties'].include?(@details_tab)

    add_permissions_inline(@provider_account)
    if params.delete :test_account
      test_account(@provider_account)
      render :action => 'show' and return
    end

    respond_to do |format|
      format.html { render :action => 'show'}
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.xml { render 'show', :locals => { :provider_account => @provider_account, :with_data => true, :with_credentials => true, :with_quota => true } }
    end
  end

  def new
    @title = _('New Provider Account')
    @provider = Provider.find(params[:provider_id])
    require_privilege(Privilege::CREATE, ProviderAccount, @provider)

    @provider_account = ProviderAccount.new(:quota => Quota.new,
                                            :provider => @provider)
    @provider_account.build_credentials
  end

  def create
    @provider = Provider.find(params[:provider_id] || params[:provider_account][:provider_id])
    require_privilege(Privilege::CREATE, ProviderAccount, @provider)
    credentials_hash = credentials_hash_prepare

    transform_quota_param(:provider_account)
    @provider_account = ProviderAccount.new(params[:provider_account])
    @provider_account.provider = @provider
    @provider_account.credentials_hash = credentials_hash
    @provider_account.build_credentials
    @provider_account.quota = Quota.new(params[:provider_account][:quota_attributes])
    @provider_account.pool_families << PoolFamily.default

    if @provider_account.save
      @provider_account.assign_owner_roles(current_user)

      respond_to do |format|
        format.html do
          flash[:notice] = t('provider_accounts.flash.notice.account_added', :list => @provider_account.name, :count => 1)
          redirect_to provider_path(@provider, :details_tab => 'accounts')
        end
        format.xml do
          render('show',
                 :locals => { :provider_account => @provider_account,
                              :with_credentials => true,
                              :with_quota => true },
                 :status => :created)
        end
      end
    else
      respond_to do |format|
        format.html do
          @title = _('New Provider Account')
          render :action => 'new'
        end
        format.xml do
          render('api/validation_error',
                 :locals => { :errors => @provider_account.errors },
                 :status => :unprocessable_entity)
        end
      end
    end
  rescue Exception => ex
    log_backtrace(ex, 'Exception caught', :warn)

    respond_to do |format|
      format.html do
        error = humanize_error(ex.message, :context => :deltacloud)
        flash[:error] = t('provider_accounts.flash.error.account_not_added',
                          :list => @provider_account.name, :count => 1) + ": #{error}"
        render :action => 'new'
      end
      format.xml { render 'api/error', :locals => { :error => ex }, :status => 500 }
    end
  end

  def edit
    @provider_account = ProviderAccount.find(params[:id])
    @title = _('Edit Account: %s') % @provider_account.name
    require_privilege(Privilege::MODIFY,@provider_account)
    load_provider
  end

  def update
    @provider_account = ProviderAccount.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider_account.provider)
    require_privilege(Privilege::MODIFY, @provider_account)
    credentials_hash = credentials_hash_prepare
    transform_quota_param(:provider_account)
    @provider_account.assign_attributes(params[:provider_account])
    @provider_account.credentials_hash = credentials_hash

    if @provider_account.save
      respond_to do |format|
        format.html do
          flash[:notice] = _('Provider Account updated')
          redirect_to provider_path(@provider_account.provider, :details_tab => 'accounts')
        end
        format.xml do
          render 'show',
                 :locals => { :provider_account => @provider_account,
                              :with_credentials => true,
                              :with_quota => true },
                 :status => :ok
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = _('Provider Account wasn\'t updated')
          render :action => :edit
        end
        format.xml do
          render 'api/validation_error',
                 :locals => { :errors => @provider_account.errors },
                 :status => :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @provider_account = ProviderAccount.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider_account)

    respond_to do |format|
      if @provider_account.safe_destroy
        format.html do
          flash[:notice] = _('Provider account was deleted')
          redirect_to provider_path(@provider_account.provider,
                                         :details_tab => 'accounts')
        end
        format.xml do
          render :nothing => true, :status => :no_content
        end
      else
        format.html do
          flash[:error] = @provider_account.errors.full_messages
          redirect_to provider_path(@provider_account.provider,
                                         :details_tab => 'accounts')
        end
        format.xml do
          raise Aeolus::Conductor::API::Error.new(500, @provider_account.errors.full_messages.join(', '))
        end
      end
    end
  end

  def multi_destroy
    @provider = Provider.find(params[:provider_id])

    if params[:accounts_selected].blank?
      flash[:warning] = _('You must select some accounts first.')
      redirect_to provider_path(@provider, :details_tab => 'accounts')

      return
    end

    succeeded = []
    failed = []
    ProviderAccount.find(params[:accounts_selected]).each do |account|
      if !check_privilege(Privilege::MODIFY, account)
        failed << _('%s: You have insufficient privileges to perform the selected action.') % account.name
      elsif account.safe_destroy
        succeeded << account.name
      else
        failed << _('Account %s was not deleted: %s') % [account.name, account.errors.full_messages.join(', ')]
      end
    end

    if succeeded.present?
      flash[:notice] = t('provider_accounts.flash.notice.account_deleted',
                         :count => succeeded.length,
                         :list => succeeded.join(', '))
    end
    flash[:error] = failed if failed.present?
    redirect_to provider_path(@provider, :details_tab => 'accounts')
  end

  def filter
    redirect_to_original({"provider_accounts_preset_filter" => params[:provider_accounts_preset_filter], "provider_accounts_search" => params[:provider_accounts_search]})
  end

  protected

  def test_account(account)
    if account.valid_credentials?
      flash.now[:notice] = _('Test Connection Success: Valid Account Details')
    else
      flash.now[:error] = _('Test Connection Failed: Invalid Account Details')
    end
  rescue
    flash.now[:error] = _('Test Connection Failed: Could not connect to Provider')
  end

  def load_provider
    if params[:provider_id]
      @provider = Provider.list_for_user(current_session, current_user, Privilege::VIEW).find(params[:provider_id])
    end
  end

  def load_accounts
    @provider_accounts = ProviderAccount.
      apply_filters(:preset_filter_id =>
                      params[:provider_accounts_preset_filter],
                    :search_filter => params[:provider_accounts_search]).
      list_for_user(current_session, current_user, Privilege::VIEW)
    @provider_accounts = @provider_accounts.where(:provider_id => @provider.id) if @provider
  end

  def credentials_hash_prepare
    if params[:provider_account][:credentials]
      params[:provider_account].delete(:credentials)
    elsif params[:provider_account][:credentials_attributes]
      params[:provider_account].delete(:credentials_attributes)
    else
      nil
    end
  end
end
