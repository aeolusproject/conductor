#
#   Copyright 2012 Red Hat, Inc.
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

class PoolFamiliesToProviderAccountsAssociationsController < ApplicationController
  before_filter :require_user

  def index
    @pool_family = PoolFamily.find(params[:pool_family_id])
    require_privilege(Privilege::VIEW, @pool_family)
    respond_to do |format|
      format.xml do
        render :partial => 'list.xml'
      end
    end
  end

  def show
    pool_family = PoolFamily.find(params[:pool_family_id])
    require_privilege(Privilege::VIEW, pool_family)
    provider_account = ProviderAccount.find(params[:id])
    respond_to do |format|
      if pool_family.provider_accounts.where(:id => provider_account.id).size == 1
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.xml { render :nothing => true, :status => :not_found }
      end
    end
  end

  def update
    @pool_family = PoolFamily.find(params[:pool_family_id])
    require_privilege(Privilege::MODIFY, @pool_family)

    provider_account = ProviderAccount.find(params[:id])

    respond_to do |format|
      if check_privilege(Privilege::USE, provider_account) and
          !@pool_family.provider_accounts.include?(provider_account) and
          @pool_family.provider_accounts << provider_account
        format.xml { render :nothing => true, :status => :created }
      else
        format.xml { render :template => 'api/validation_error',
          :status => :bad_request,
          :locals => { :errors => @pool_family.errors }}
      end
    end
  end

  def destroy
    @pool_family = PoolFamily.find(params[:pool_family_id])
    require_privilege(Privilege::MODIFY, @pool_family)

    provider_account = ProviderAccount.find(params[:id])

    respond_to do |format|
      if @pool_family.provider_accounts.delete provider_account
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.xml { render :template => 'api/validation_error',
          :status => :bad_request,
          :locals => { :errors => @pool_family.errors }}
      end
    end
  end

end
