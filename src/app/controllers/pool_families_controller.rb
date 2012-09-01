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

require 'will_paginate/array'

class PoolFamiliesController < ApplicationController
  include QuotaAware

  before_filter :require_user
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_pool_families, :only =>[:index, :show]

  def index
    @title = t("pool_families.pool_families")
    clear_breadcrumbs
    save_breadcrumb(pool_families_path)
    set_admin_environments_tabs 'pool_families'
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.xml do
        render :partial => 'list.xml'
      end
    end
  end

  def new
    @title = t("pool_families.index.new_pool_family")
    require_privilege(Privilege::CREATE, PoolFamily)
    @pool_family = PoolFamily.new(:quota => Quota.new)
  end

  def create
    set_quota_param(:pool_family)
    @pool_family = PoolFamily.new(params[:pool_family])
    @pool_family.quota = @quota = Quota.new
    require_privilege(Privilege::CREATE, PoolFamily)
    set_quota(@pool_family)

    respond_to do |format|
      if @pool_family.save
        @pool_family.assign_owner_roles(current_user)
        flash[:notice] = t"pool_families.flash.notice.added"
        format.html { redirect_to pool_families_path }
        format.xml {
          render :show, :locals => { :pool_family => @pool_family }}
      else
        flash.now[:warning] = t"pool_families.flash.warning.creation_failed"
        format.html { render :new and return }
        format.xml { render :template => 'api/validation_error', :locals => { :errors => @pool_family.errors }, :status => :bad_request}
      end
    end
  end

  def edit
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    @title = @pool_family.name
    @pool_family.quota ||= Quota.new
  end

  def update
    set_quota_param(:pool_family)
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    set_quota(@pool_family)

    respond_to do |format|
      if @pool_family.update_attributes(params[:pool_family])
        format.html {
          flash[:notice] = t "pool_families.flash.notice.updated"
          redirect_to pool_families_path
        }
        format.xml {
          render :show, :locals => { :pool_family => @pool_family } }
      else
        format.html {
          flash[:error] = t "pool_families.flash.error.not_updated"
          render :action => 'edit' and return
        }
        format.xml { render :template => 'api/validation_error', :locals => { :errors => @pool_family.errors }, :status => :bad_request}
      end
    end
  end

  def show
    @pool_family = PoolFamily.find(params[:id])
    @title = @pool_family.name
    save_breadcrumb(pool_family_path(@pool_family), @pool_family.name)
    require_privilege(Privilege::VIEW, @pool_family)
    @all_images = Aeolus::Image::Warehouse::Image.by_environment(@pool_family.name)
    @images = paginate_collection(@all_images, params[:page], PER_PAGE)

    load_pool_family_tabs

    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @view and return
      end
      format.xml { render :show, :locals => { :pool_family => @pool_family } }
    end
  end

  def destroy
    pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, pool_family)
    if pool_family == PoolFamily.default
      flash[:error] = t("pool_families.flash.error.default_pool_family_not_deleted")
    elsif pool_family.destroy
      flash[:notice] = t "pool_families.flash.notice.deleted"
    else
      flash[:error] = t "pool_families.flash.error.not_deleted"
    end

    respond_to do |format|
      format.html { redirect_to pool_families_path }
      format.xml {
        if flash[:error].present?
          raise(Aeolus::Conductor::API::Error.new(500, flash[:error]))
        else
          render :destroy, :locals => { :pool_family_id => pool_family.id }
        end
      }
    end
  end

  def add_provider_accounts
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)

    if ProviderAccount.count == 0
      flash[:error] = t('pool_families.flash.error.no_provider_accounts')
      redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts') and return
    end

    @provider_accounts = ProviderAccount.
      list_for_user(current_session, current_user, Privilege::USE).
      where('provider_accounts.id not in (?)',
            @pool_family.provider_accounts.empty? ?
            0 : @pool_family.provider_accounts.map(&:id))

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

  def set_params_and_header
    @header = [
      {:name => '', :sortable => false},
      {:name => t("pool_families.index.name"), :sort_attr => :name},
      {:name => t("quota_used"), :sort_attr => :name},
      {:name => t("pool_families.index.quota_limit"), :sort_attr => :name},
    ]
  end

  def load_pool_families
    @pool_families = PoolFamily.list_for_user(current_session, current_user,
                                              Privilege::VIEW).
      order(sort_column(PoolFamily) + ' ' + sort_direction)
  end

  def load_pool_family_tabs
    @tabs = [{:name => t('pools.pools'),:view => 'pools', :id => 'pools', :count => @pool_family.pools.count},
             {:name => t('accounts'), :view => 'provider_accounts', :id => 'provider_accounts', :count => @pool_family.provider_accounts.count},
             {:name => t('images.index.images'), :view => 'images', :id => 'images', :count => @all_images.count},
    ]
    add_permissions_tab(@pool_family)
    details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    @view = @details_tab[:view]

    case
    when @view == 'pools'
      @pools_header = [
        {:name => t("pool_families.index.pool_name"), :sortable => false},
        {:name => t("pool_families.index.deployments"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.total_instancies"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.pending_instances"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.failed_instances"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.quota_used"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.active_instances"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.available_instances"), :class => 'center', :sortable => false},
        {:name => t("pool_families.index.catalog"), :sortable => false},
        {:name => '', :sortable => false}
      ]
    when @view == 'images'
      @header = [
        { :name => 'checkbox', :class => 'checkbox', :sortable => false },
        { :name => t('images.index.name'), :sort_attr => :name },
        { :name => t('images.index.os'), :sort_attr => :name },
        { :name => t('images.index.os_version'), :sort_attr => :name },
        { :name => t('images.index.architecture'), :sort_attr => :name },
        { :name => t('images.index.last_rebuild'), :sortable => false },
      ]
    end

  end
end
