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

require 'will_paginate/array'

class PoolFamiliesController < ApplicationController
  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pool_families, :only =>[:show]
  before_filter :load_tab_captions_and_details_tab, :only => [:show]

  def index
    clear_breadcrumbs
    save_breadcrumb(pool_families_path)
    load_pool_families
  end

  def new
    require_privilege(Privilege::CREATE, PoolFamily)
    @pool_family = PoolFamily.new(:quota => Quota.new)
  end

  def create
    @pool_family = PoolFamily.new(params[:pool_family])
    require_privilege(Privilege::CREATE, PoolFamily)

    unless @pool_family.save
      flash.now[:warning] = "Pool family's creation failed."
      render :new and return
    else
      @pool_family.assign_owner_roles(current_user)
      flash[:notice] = "Pool family was added."
      redirect_to pool_families_path
    end
  end

  def edit
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    @pool_family.quota ||= Quota.new
  end

  def update
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)

    unless @pool_family.update_attributes(params[:pool_family])
      flash[:error] = "Pool Family wasn't updated!"
      render :action => 'edit' and return
    else
      flash[:notice] = "Pool Family was updated!"
      redirect_to pool_families_path
    end
  end

  def show
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::VIEW, @pool_family)

    save_breadcrumb(pool_family_path(@pool_family), @pool_family.name)

    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
    end
  end

  def destroy
    pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, pool_family)
    if pool_family.destroy
      flash[:notice] = "Pool Family was deleted!"
    else
      flash[:error] = "Pool Family cannot be deleted!"
    end
    redirect_to pool_families_path
  end

  def add_provider_account
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    @provider_account = ProviderAccount.find(params[:provider_account_id])
    require_privilege(Privilege::VIEW, @provider_account)

    @pool_family.provider_accounts << @provider_account
    flash[:notice] = "Provider Account has been added"
    redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts')
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    PoolFamily.find(params[:pool_family_selected]).each do |pool_family|
      if check_privilege(Privilege::MODIFY, pool_family) && pool_family.destroy
        deleted << pool_family.name
      else
        not_deleted << pool_family.name
      end
    end
    if deleted.size > 0
      flash[:notice] = t 'pool_families.index.deleted', :list => deleted.join(', ')
    end
    if not_deleted.size > 0
      flash[:error] = t 'pool_families.index.not_deleted', :list => not_deleted.join(', ')
    end
    redirect_to pool_families_path
  end

  def multi_destroy_provider_accounts
    @pool_family = PoolFamily.find(params[:pool_family_id])
    require_privilege(Privilege::MODIFY, @pool_family)

    ProviderAccount.find(params[:provider_account_selected]).each do |provider_account|
      if check_privilege(Privilege::VIEW, provider_account)
        @pool_family.provider_accounts.delete provider_account
      end
    end

    redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts')
  end

  protected

  def load_tab_captions_and_details_tab
    @tab_captions = ['Properties', 'History', 'Permissions', 'Provider Accounts', 'Pools']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    @provider_accounts_header = [{:name => "Provider Account", :sort_attr => :name}]
  end

  def set_params_and_header
    @header = [
      {:name => '', :sortable => false},
      {:name => t("pool_families.index.name"), :sort_attr => :name},
      {:name => t("pool_families.index.quota_used"), :sort_attr => :name},
      {:name => t("pool_families.index.quota_limit"), :sort_attr => :name},
    ]
  end

  def load_pool_families
    @pool_families = PoolFamily.list_for_user(current_user, Privilege::VIEW).paginate(
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') + ' ' + (params[:order_dir] || 'asc'))
  end
end
