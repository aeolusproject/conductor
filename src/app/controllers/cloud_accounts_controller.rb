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

  def new
    @provider = Provider.find(params[:provider_id])
    @cloud_account = CloudAccount.new
    require_privilege(Privilege::ACCOUNT_MODIFY, @provider)
  end

  def create
    @provider = Provider.find(params[:cloud_account][:provider_id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
    if not params[:cloud_account][:x509_cert_priv_file].nil?
      params[:cloud_account][:x509_cert_priv] = params[:cloud_account][:x509_cert_priv_file].read
    end
    params[:cloud_account].delete :x509_cert_priv_file
    if not params[:cloud_account][:x509_cert_pub_file].nil?
      params[:cloud_account][:x509_cert_pub] = params[:cloud_account][:x509_cert_pub_file].read
    end
    params[:cloud_account].delete :x509_cert_pub_file
    @cloud_account = CloudAccount.new(params[:cloud_account])
    unless @cloud_account.valid_credentials?
      flash[:notice] = "The entered credential information is incorrect"
      redirect_to :controller => "provider", :action => "accounts", :id => @provider
    else
      quota = Quota.new
      quota.maximum_running_instances = quota_from_string(params[:quota][:maximum_running_instances])
      quota.save!
      @cloud_account.quota_id = quota.id
      @cloud_account.zones << Zone.default
      @cloud_account.save!
      if request.post? && @cloud_account.save && @cloud_account.populate_realms_and_images
        flash[:notice] = "Provider account added."
      end
      redirect_to :controller => "provider", :action => "accounts", :id => @provider
      condormatic_classads_sync
    end
  end

  def edit
    @cloud_account = CloudAccount.find(params[:id])
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
  end

  def update_accounts
    params[:cloud_accounts].each do |id, attributes|
      @cloud_account = CloudAccount.find(id)
      require_privilege(Privilege::ACCOUNT_MODIFY, @cloud_account.provider)

      # blank password means the user didn't change it -- don't update it then
      if attributes.has_key? :password and String(attributes[:password]).empty?
        attributes.delete :password
      end
      @cloud_account.quota.maximum_running_instances = quota_from_string(params[:quota][id][:maximum_running_instances])
      private_cert = attributes[:x509_cert_priv_file]
      if private_cert.nil?
        attributes.delete :x509_cert_priv
      else
        attributes[:x509_cert_priv] = private_cert.read
        attributes.delete :x509_cert_priv_file
      end
      public_cert = attributes[:x509_cert_pub_file]
      if public_cert.nil?
        attributes.delete :x509_cert_pub
      else
        attributes[:x509_cert_pub] = public_cert.read
        attributes.delete :x509_cert_pub_file
      end
      @cloud_account.update_attributes!(attributes)
      @cloud_account.quota.save!
    end
    redirect_to :controller => 'provider', :action => 'accounts', :id => params[:provider][:id]
  end

  def update
    @cloud_account = CloudAccount.find(params[:cloud_account][:id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@cloud_account.provider)
    if @cloud_account.update_attributes(params[:cloud_account])
      flash[:notice] = "Cloud Account updated!"
      redirect_to :controller => 'provider', :action => 'accounts', :id => @cloud_account.provider.id
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
    acct = CloudAccount.find(params[:id])
    provider = acct.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,provider)
    if acct.destroyable?
      CloudAccount.destroy(params[:id])
      flash[:notice] = "Cloud Account destroyed"
    else
      flash[:notice] = "Cloud Account could not be destroyed"
    end
    redirect_to :controller => 'provider', :action => 'accounts', :id => provider.id
  end

  private

  def quota_from_string(quota_raw)
    if quota_raw.nil? or quota_raw.empty? or quota_raw.downcase == 'unlimited'
      return nil
    else
      return Integer(quota_raw)
    end
  end
end
