#
#   Copyright 2013 Red Hat, Inc.
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

class PoolProviderAccountOptionsController < ApplicationController

  before_filter :require_user
  before_filter :load_pool
  before_filter :require_privileged_user_for_modify, :except => :index

  def index
    require_privilege(Alberich::Privilege::VIEW, @pool)

    @provider_accounts = @pool.pool_family.provider_accounts
    @options =
      PoolProviderAccountOption.
        where(:pool_id => @pool, :provider_account_id => @provider_accounts).all
  end

  def new
    provider_account = ProviderAccount.find(params[:provider_account_id])
    @pool_provider_account_option = PoolProviderAccountOption.new(:score => 0, :provider_account => provider_account)
  end

  def create
    @pool_provider_account_option = PoolProviderAccountOption.new(params[:pool_provider_account_option])
    @pool_provider_account_option.pool = @pool

    if @pool_provider_account_option.save
      redirect_to pool_provider_selection_provider_account_options_path(@pool), :notice => _('Provider Account Weight successfully modified.')
    else
      render :new
    end
  end

  def edit
    @pool_provider_account_option = PoolProviderAccountOption.find(params[:id])
  end

  def update
    @pool_provider_account_option = PoolProviderAccountOption.find(params[:id])
    @pool_provider_account_option.update_attributes(params[:pool_provider_account_option])

    if @pool_provider_account_option.save
      redirect_to pool_provider_selection_provider_account_options_path(@pool), :notice => _('Provider Account Weight successfully modified.')
    else
      render :edit
    end
  end

  private

  def load_pool
    @pool = Pool.find(params[:pool_id])
  end

  def require_privileged_user_for_modify
    require_privilege(Alberich::Privilege::MODIFY, @pool)
  end

end
