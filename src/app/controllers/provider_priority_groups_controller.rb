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

class ProviderPriorityGroupsController < ApplicationController

  before_filter :require_user
  before_filter :load_pool
  before_filter :load_providers, :only => [:new, :create, :edit, :update]
  before_filter :require_privileged_user_for_modify, :except => :index

  def index
    require_privilege(Privilege::VIEW, @pool)

    @strategy = ProviderSelection::Base.find_strategy_by_name(params[:name])
    @priority_groups = @pool.provider_priority_groups
  end

  def new
    @priority_group = ProviderPriorityGroup.new
  end

  def create
    @priority_group = ProviderPriorityGroup.new(params[:provider_priority_group])
    @priority_group.pool = @pool

    unless @priority_group.save
      render :new
      return
    end

    if params[:provider_ids].present?
      selected_providers =
        Provider.list_for_user(current_session, current_user, Privilege::USE).
          find(params[:provider_ids])
      @priority_group.providers = selected_providers
    end

    if params[:provider_account_ids].present?
      selected_provider_accounts =
        ProviderAccount.list_for_user(current_session, current_user, Privilege::USE).
          find(params[:provider_account_ids])
      @priority_group.add_provider_accounts(selected_provider_accounts)
    end

    redirect_to pool_provider_selection_provider_priority_groups_path(@priority_group.pool),
                :notice => t('provider_priority_groups.flash.created')
  end

  def edit
    @priority_group = ProviderPriorityGroup.find(params[:id])
  end

  def update
    @priority_group = ProviderPriorityGroup.find(params[:id])

    unless @priority_group.update_attributes!(params[:provider_priority_group])
      render :edit
      return
    end

    if params[:provider_ids].present?
      selected_providers =
        Provider.list_for_user(current_session, current_user, Privilege::USE).
          find(params[:provider_ids])
      @priority_group.providers = selected_providers
    end

    @priority_group.provider_accounts.clear
    if params[:provider_account_ids].present?
      selected_provider_accounts =
        ProviderAccount.list_for_user(current_session, current_user, Privilege::USE).
          find(params[:provider_account_ids])
      @priority_group.add_provider_accounts(selected_provider_accounts)
    end

    redirect_to pool_provider_selection_provider_priority_groups_path(@priority_group.pool),
                :notice => t('provider_priority_groups.flash.updated')
  end

  def destroy
    @pool.provider_priority_groups.find(params[:id]).destroy
    redirect_to :back, :notice => t('provider_priority_groups.flash.deleted')
  end

  private

  def load_pool
    @pool = Pool.find(params[:pool_id])
  end

  def load_providers
    @providers = Provider.list_for_user(current_session, current_user, Privilege::USE)
  end

  def require_privileged_user_for_modify
    require_privilege(Privilege::MODIFY, @pool)
  end

end
