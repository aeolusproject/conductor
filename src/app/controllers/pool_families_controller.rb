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
    set_admin_environments_tabs 'pool_families'
    load_pool_families
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def new
    require_privilege(Privilege::CREATE, PoolFamily)
    @pool_family = PoolFamily.new(:quota => Quota.new)
  end

  def create
    @pool_family = PoolFamily.new(params[:pool_family])
    require_privilege(Privilege::CREATE, PoolFamily)

    unless @pool_family.save
      flash.now[:warning] = t"pool_families.flash.warning.creation_failed"
      render :new and return
    else
      @pool_family.assign_owner_roles(current_user)
      flash[:notice] = t"pool_families.flash.notice.added"
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
      flash[:error] = t "pool_families.flash.error.not_updated"
      render :action => 'edit' and return
    else
      flash[:notice] = t "pool_families.flash.notice.updated"
      redirect_to pool_families_path
    end
  end

  def show
    @pool_family = PoolFamily.find(params[:id])
    save_breadcrumb(pool_family_path(@pool_family), @pool_family.name)
    require_privilege(Privilege::VIEW, @pool_family)
    load_pool_family_tabs


    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @view and return
      end
    end
  end

  def destroy
    pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, pool_family)
    if pool_family.destroy
      flash[:notice] = t "pool_families.flash.notice.deleted"
    else
      flash[:error] = t "pool_families.flash.error.not_deleted"
    end
    redirect_to pool_families_path
  end

  def add_provider_accounts
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    @provider_accounts = ProviderAccount.
      list_for_user(current_user, Privilege::USE).
      where('id not in (?)', @pool_family.provider_accounts.empty? ?
                             0 : @pool_family.provider_accounts.map(&:id))

    load_tab_captions_and_details_tab('provider_accounts')
    load_pool_family_tabs

    added = []
    not_added = []

    if params[:accounts_selected].blank?
      flash[:error] = t"pool_families.flash.error.select_to_add_accounts" if request.post?
    else
      ProviderAccount.find(params[:accounts_selected]).each do |provider_account|
        if check_privilege(Privilege::USE, provider_account) and
            !@pool_family.provider_accounts.include?(provider_account) and
            @pool_family.provider_accounts << provider_account
          added << provider_account.name
        else
          not_added << provider_account.name
        end
      end
      unless added.empty?
        flash[:notice] = "#{t('pool_families.flash.notice.provider_accounts_added')}: #{added.join(', ')}"
      end
      unless not_added.empty?
        flash[:error] = "#{t('pool_families.flash.error.provider_accounts_not_added')}: #{not_added.join(', ')}"
      end
      respond_to do |format|
        format.html { redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts') }
        format.js { render :partial => 'provider_accounts' }
      end
    end
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
      flash[:notice] = t 'pool_families.flash.notice.more_deleted', :list => deleted.join(', ')
    end
    if not_deleted.size > 0
      flash[:error] = t 'pool_families.flash.error.more_not_deleted', :list => not_deleted.join(', ')
    end
    redirect_to pool_families_path
  end

  def remove_provider_accounts
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    load_tab_captions_and_details_tab('provider_accounts')
    removed=[]
    not_removed=[]

    if params[:accounts_selected].blank?
      flash[:error] = t"pool_families.flash.error.select_to_remove_accounts"
    else
      ProviderAccount.find(params[:accounts_selected]).each do |provider_account|
        if @pool_family.provider_accounts.delete provider_account
          removed << provider_account.name
        else
          not_removed << provider_account.name
        end
      end
      unless removed.empty?
        flash[:notice] = "#{t('pool_families.flash.notice.provider_accounts_removed')}: #{removed.join(', ')}"
      end
      unless not_removed.empty?
        flash[:error] = "#{t('pool_families.flash.error.provider_accounts_not_removed')}: #{not_removed.join(', ')}"
      end
    end
    respond_to do |format|
      format.html { redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts') }
        format.js { render :partial => 'provider_accounts' }
    end
  end

  protected

  def load_tab_captions_and_details_tab(details_tab = 'properties')
    @tab_captions = ['Properties', 'History', 'Permissions', 'Provider Accounts', 'Pools']
    @details_tab_name = params[:details_tab].blank? ? details_tab : params[:details_tab]
    @provider_accounts_header = [
           { :name => 'checkbox', :sortable => false, :class => 'checkbox' },
           { :name => t("provider_accounts.index.provider_account_name"), :sortable => false },
           { :name => t("provider_accounts.index.username"), :sortable => false},
           { :name => t("provider_accounts.index.provider_name"), :sortable => false },
           { :name => t("provider_accounts.index.provider_type"), :sortable => false },
           { :name => t("quota_used"), :sortable => false, :class => 'center' },
           { :name => t("provider_accounts.index.quota_limit"), :sortable => false, :class => 'center' }
                                ]
  end

  def set_params_and_header
    @header = [
      {:name => '', :sortable => false},
      {:name => t("pool_families.index.name"), :sort_attr => :name},
      {:name => t("quota_used"), :sort_attr => :name},
      {:name => t("pool_families.index.quota_limit"), :sort_attr => :name},
    ]
  end

  def load_pool_families
    @pool_families = PoolFamily.list_for_user(current_user, Privilege::VIEW).paginate(
      :page => params[:page] || 1,
      :order => (sort_column(PoolFamily) + ' ' + sort_direction))
  end

  def load_pool_family_tabs
    @tabs = [{:name => t('pools.pools'),:view => 'pools', :id => 'pools', :count => @pool_family.pools.count},
             {:name => t('accounts'), :view => 'provider_accounts', :id => 'provider_accounts', :count => @pool_family.provider_accounts.count},
    ]
    add_permissions_tab(@pool_family)
    details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    @view = @details_tab[:view]
  end
end
