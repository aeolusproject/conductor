#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

class ProviderAccountsController < ApplicationController
  before_filter :require_user
  before_filter :load_accounts, :only => [:index,:show]

  def index
    clear_breadcrumbs
    save_breadcrumb(provider_accounts_path)
    load_accounts

    respond_to do |format|
      format.html
      format.xml { render :text => ProviderAccount.xml_export(@provider_accounts) }
    end
  end

  def show
    @tab_captions = ['Properties', 'Credentials', 'History', 'Permissions']
    @account = ProviderAccount.find(params[:id])
    @account_id = @account.credentials_hash['account_id']
    require_privilege(Privilege::VIEW, @account)
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    if params.delete :test_account
      test_account(@account)
      render :action => 'show' and return
    end

    save_breadcrumb(provider_account_path(@account), @account.name)

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
      flash[:error] = "You don't have any provider yet. Please create one!"
    else
      @selected_provider = Provider.find(params[:provider_id])
    end
  end

  def create
    unless params[:provider_account][:provider].nil?
      provider = params[:provider_account].delete(:provider)
      params[:provider_account][:provider_id] = Provider.find_by_name(provider).id
    end
    @selected_provider = @provider = Provider.find(params[:provider_account][:provider_id])
    require_privilege(Privilege::CREATE, ProviderAccount, @provider)

    @providers = Provider.all
    @provider_account = ProviderAccount.new(params[:provider_account])
    @provider_account.provider = @provider
    @provider_account.quota = @quota = Quota.new

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @provider_account.quota.set_maximum_running_instances(limit)

    @provider_account.pool_families << PoolFamily.default
    begin
      if @provider_account.save
        @provider_account.assign_owner_roles(current_user)
        @provider_account.populate_realms
        flash[:notice] = t('provider_accounts.index.account_added', :list => @provider_account.name, :count => 1)
        redirect_to edit_provider_path(@provider_account.provider, :view => 'filter', :details_tab => 'connectivity')
      else
        flash[:error] = "Cannot add the provider account."
        render :action => 'new' and return
      end
    rescue Exception => e
      flash[:error] = "#{t('provider_accounts.index.account_not_added', :list => @provider_account.name,
        :count => 1)}: #{e.message}"
      render :action => 'new' and return
    end
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
    @provider_accounts = ProviderAccount.find(params[:accounts_selected]).each do |account|
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
    redirect_to edit_provider_path(@provider_accounts.first.provider, :view => 'filter', :details_tab => 'connectivity')
  end

  def set_selected_provider
    @quota = Quota.new
    @provider_account = ProviderAccount.new
    respond_to do |format|
      format.html {
        @providers = Provider.find(:all)
        @selected_provider = Provider.find(params[:provider_account][:provider_id])
        render :action => 'new', :layout => true
      }
      format.js {
        @providers = Provider.find(:all)
        @selected_provider = Provider.find(params[:provider_account][:provider_id])
        render :partial => 'provider_selection'
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

  def load_accounts
    @provider_accounts = ProviderAccount.list_for_user(current_user, Privilege::VIEW)
  end
end
