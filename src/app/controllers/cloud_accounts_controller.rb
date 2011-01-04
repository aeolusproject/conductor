#
# Copyright (C) 2010 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class CloudAccountsController < ApplicationController
  before_filter :require_user
  before_filter :load_providers

  helper :providers

  def section_id
    'administration'
  end

  def index
    @provider = Provider.find(params[:provider_id])
    require_privilege(Privilege::ACCOUNT_VIEW, @provider)
  end

  def new
    @provider = Provider.find(params[:provider_id])
    @cloud_account = CloudAccount.new
    @quota = Quota.new
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)
  end

  def create
    @provider = Provider.find(params[:provider_id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
    @cloud_account = CloudAccount.new(params[:cloud_account])
    @cloud_account.provider = @provider
    @cloud_account.quota = @quota = Quota.new

    if params[:test_account]
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

    @cloud_account.pool_families << PoolFamily.default
    @cloud_account.save!
    if @cloud_account.populate_realms
      flash[:notice] = "Provider account added."
    end
    redirect_to provider_accounts_path(@provider)
    kick_condor
  end

  def edit
    @cloud_account = CloudAccount.find(params[:id])
    @quota = @cloud_account.quota
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
  end

  def update_accounts
    @provider = Provider.find(params[:provider][:id])
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)

    success = true
    @provider.cloud_accounts.each do |cloud_account|
      attributes = params[:cloud_accounts][cloud_account.id.to_s]

      password = attributes[:password]
      # blank password means the user didn't change it -- don't update it then
      if password.blank?
        attributes.delete :password
      end
      cloud_account.quota.maximum_running_instances = quota_from_string(params[:quota][cloud_account.id.to_s][:maximum_running_instances])

      private_cert = attributes[:x509_cert_priv_file]
      unless private_cert.blank?
        attributes[:x509_cert_priv] = private_cert.read
      end
      attributes.delete :x509_cert_priv_file

      public_cert = attributes[:x509_cert_pub_file]
      unless public_cert.blank?
        attributes[:x509_cert_pub] = public_cert.read
      end
      attributes.delete :x509_cert_pub_file

      begin
        cloud_account.update_attributes!(attributes)
        cloud_account.quota.save!
      rescue
        success = false
      end
    end
    if success
      flash[:notice] = "Account updated."
      redirect_to :controller => 'providers', :action => 'accounts', :id => @provider
    else
      flash.now[:notice] = "Error updating the cloud account."
      render :template => 'provider/accounts'
    end
  end

  def update
    @cloud_account = CloudAccount.find(params[:id])
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)
    @quota = @cloud_account.quota

    limit = params[:quota][:maximum_running_instances] if params[:quota]
    @cloud_account.quota.set_maximum_running_instances(limit)
    if @cloud_account.update_attributes(params[:cloud_account])
      flash[:notice] = "Cloud Account updated!"
      redirect_to provider_accounts_path(@provider)
    else
      render :action => :edit
    end
  end

  def key
    @cloud_account = CloudAccount.find(params[:id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@cloud_account.provider)
    unless @cloud_account.instance_key.nil?
      render :text => @cloud_account.instance_key.pem
    end
  end

  def destroy
    account = CloudAccount.find(params[:id])
    provider = account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY, provider)
    if account.destroy
      flash[:notice] = "Cloud Account destroyed"
    else
      flash[:error] = "Cloud Account could not be destroyed"
    end
    redirect_to provider_accounts_path(provider)
  end

  def test_account(account)
    if account.valid_credentials?
      flash.now[:notice] = "Test Connection Success: Valid Account Details"
    else
      flash.now[:error] = "Test Connection Failed: Invalid Account Details"
    end
  rescue
    flash.now[:error] = "Test Connection Failed: Could not connect to provider"
  end

  private

  def load_providers
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)
  end
end
