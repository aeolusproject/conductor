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
  before_filter :require_user
  before_filter :load_accounts, :only => [:index,:show]

  def index
    clear_breadcrumbs
    save_breadcrumb(provider_accounts_path)
    load_accounts

    respond_to do |format|
      #xml list of provider_accounts for aeolus-image, aeolus-image could work with prov. accounts list for givent provider
      #to resemble html views logic, so this route could be removed (provider_accounts could be user only as nested resource)
      format.xml { render :text => ProviderAccount.xml_export(@provider_accounts) }
    end
  end

  def show
    @tab_captions = [t('provider_accounts.tab_captions.properties'), t('provider_accounts.tab_captions.credentials'), t('provider_accounts.tab_captions.history'), t('provider_accounts.tab_captions.permissions')]
    @provider_account = ProviderAccount.find(params[:id])
    @provider = Provider.find(params[:provider_id])
    @account_id = @provider_account.credentials_hash['account_id']
    require_privilege(Privilege::VIEW, @provider_account)
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

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
    end
  end

  def new
    @provider_account = ProviderAccount.new
    @quota = Quota.new
    @providers = Provider.all
    if @providers.empty?
      flash[:error] = t"provider_accounts.flash.error.no_provider"
    else
      @provider = Provider.find(params[:provider_id])
    end
  end

  def create
    if params[:provider_account][:provider].present?
      @provider = Provider.find_by_name(params[:provider_account][:provider])
      params[:provider_account][:provider] = @provider
      params[:provider_id] = @provider.id
    else
      @provider = Provider.find(params[:provider_id])
    end
    require_privilege(Privilege::CREATE, ProviderAccount, @provider)
    params[:provider_account][:provider_id] = @provider.id
    @providers = Provider.all
    @provider_account = ProviderAccount.new(params[:provider_account])
    @provider_account.quota = @quota = Quota.new
    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)
    @provider_account.pool_families << PoolFamily.default
    begin
      if @provider_account.save
        @provider_account.assign_owner_roles(current_user)
        @provider_account.populate_realms
        flash[:notice] = t('provider_accounts.flash.notice.account_added', :list => @provider_account.name, :count => 1)
        redirect_to edit_provider_path(@provider, :details_tab => 'accounts')
      else
        flash[:error] = t"provider_accounts.flash.error.not_added"
        render :action => 'new' and return
      end
    rescue Exception => e
      error = humanize_error(e.message, :context => :deltacloud)
      flash[:error] = "#{t('provider_accounts.flash.error.account_not_added', :list => @provider_account.name,
        :count => 1)}: #{error}"
      render :action => 'new' and return
    end
  end

  def edit
    @provider_account = ProviderAccount.find(params[:id])
    @provider = Provider.find(params[:provider_id])
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
      flash[:notice] = t"provider_accounts.flash.notice.updated"
      redirect_to edit_provider_path(@provider, :details_tab => 'accounts')
    else
      flash[:error] = t"provider_accounts.flash.error.not_updated"
      render :action => :edit
    end
  end

  def destroy
    require_privilege(Privilege::MODIFY, @provider_account)
    @provider = Provider.find(params[:provider_id])
    if ProviderAccount.destroy(params[:id])
      flash[:notice] = t"provider_accounts.flash.notice.deleted"
    else
      flash[:error] = t"provider_accounts.flash.error.not_deleted"
    end
    redirect_to edit_provider_path(@provider, :details_tab => 'accounts')
  end

  def multi_destroy
    @provider = Provider.find(params[:provider_id])
    if params[:accounts_selected].blank?
      flash[:warning] = t"provider_accounts.flash.warning.must_select_account"
      redirect_to edit_provider_path(@provider, :details_tab => 'accounts') and return
    end

    succeeded = []
    failed = []
    @provider_accounts = ProviderAccount.find(params[:accounts_selected]).each do |account|
      if check_privilege(Privilege::MODIFY, account) && account.destroyable?
        account.destroy
        succeeded << account.label
      else
        failed << account.label
      end
    end

    unless succeeded.empty?
      flash[:notice] = t 'provider_accounts.flash.notice.account_deleted', :count => succeeded.length, :list => succeeded.join(', ')
    end
    unless failed.empty?
      flash[:error] = t 'provider_accounts.flash.error.account_not_deleted', :count => failed.length, :list => failed.join(', ')
    end
    redirect_to edit_provider_path(@provider, :details_tab => 'accounts')
  end

  def set_selected_provider
    @quota = Quota.new
    @provider_account = ProviderAccount.new
    respond_to do |format|
      format.html {
        @providers = Provider.find(:all)
        @provider = Provider.find(params[:provider_account][:provider_id])
        render :action => 'new', :layout => true
      }
      format.js {
        @providers = Provider.find(:all)
        @provider = Provider.find(params[:provider_account][:provider_id])
        render :partial => 'provider_selection'
      }

    end
  end

  def filter
    original_path = Rails.application.routes.recognize_path(params[:current_path])
    original_params = Rack::Utils.parse_nested_query(URI.parse(params[:current_path]).query)
    redirect_to original_path.merge(original_params).merge("provider_accounts_preset_filter" => params[:provider_accounts_preset_filter], "provider_accounts_search" => params[:provider_accounts_search])
  end

  protected

  def test_account(account)
    if account.valid_credentials?
      flash.now[:notice] = t"provider_accounts.flash.notice.test_connection_success"
    else
      flash.now[:error] = t"provider_accounts.flash.error.test_connection_failed_invalid"
    end
  rescue
    flash.now[:error] = t"provider_accounts.flash.error.test_connection_failed_provider"
  end

  def load_accounts
    @provider_accounts = ProviderAccount.list_for_user(current_user, Privilege::VIEW).apply_filters(:preset_filter_id => params[:provider_accounts_preset_filter], :search_filter => params[:provider_accounts_search])
  end
end
