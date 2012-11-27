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
    @title = _("Environments")
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
    @title = _("New Environment")
    require_privilege(Privilege::CREATE, PoolFamily)
    @pool_family = PoolFamily.new(:quota => Quota.new)
  end

  def create
    transform_quota_param(:pool_family)
    @pool_family = PoolFamily.new(params[:pool_family])
    @pool_family.quota = Quota.new(params[:pool_family][:quota_attributes])
    require_privilege(Privilege::CREATE, PoolFamily)

    respond_to do |format|
      if @pool_family.save
        @pool_family.assign_owner_roles(current_user)
        flash[:notice] = _("Environment was added.")
        format.html { redirect_to pool_families_path }
        format.xml { render :show,
                            :status => :created,
                            :locals => { :pool_family => @pool_family }}
      else
        format.html do
          @title = _("New Environment")
          render :new
        end
        format.xml { render :template => 'api/validation_error',
          :locals => { :errors => @pool_family.errors },
          :status => :unprocessable_entity }
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
    transform_quota_param(:pool_family)
    @pool_family = PoolFamily.find(params[:id])
    @title = @pool_family.name
    require_privilege(Privilege::MODIFY, @pool_family)

    respond_to do |format|
      if @pool_family.update_attributes(params[:pool_family])
        format.html do
          flash[:notice] = _("Environment was updated.")
          redirect_to pool_families_path
        end
        format.xml do
          render :show, :locals => { :pool_family => @pool_family }
        end
      else
        format.html do
          render :action => 'edit'
        end
        format.xml do
          render :template => 'api/validation_error',
                 :locals => { :errors => @pool_family.errors },
                 :status => :unprocessable_entity
        end
      end
    end
  end

  def show
    @pool_family = PoolFamily.find(params[:id])
    @title = @pool_family.name
    save_breadcrumb(pool_family_path(@pool_family), @pool_family.name)
    require_privilege(Privilege::VIEW, @pool_family)
    @all_images = @pool_family.base_images
    @base_images = paginate_collection(@all_images, params[:page], PER_PAGE)

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

    respond_to do |format|
      if pool_family.safe_destroy
        format.html do
          flash[:notice] = _("Environment was deleted.")
          redirect_to pool_families_path
        end
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.html do
          flash[:error] = pool_family.errors.full_messages
          redirect_to pool_families_path
        end
        format.xml { raise(Aeolus::Conductor::API::Error.new(500, pool_family.errors.full_messages.join(', '))) }
      end
    end
  end

  def add_provider_accounts
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)

    if ProviderAccount.count == 0
      flash[:error] = _("There are no Provider Accounts available.")
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
      flash[:error] = _("You must select at least one Provider Account to add.") if request.post?
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
        flash[:notice] = "#{_("These Provider Account have been added")}: #{added.join(', ')}"
      end
      unless not_added.empty?
        flash[:error] = "#{_("Could not add these Provider Accounts")}: #{not_added.join(', ')}"
      end
      respond_to do |format|
        format.html { redirect_to pool_family_path(@pool_family, :details_tab => 'provider_accounts') }
        format.js { render :partial => 'provider_accounts' }
      end
    end
  end

  def remove_provider_accounts
    @pool_family = PoolFamily.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool_family)
    removed=[]
    not_removed=[]

    if params[:accounts_selected].blank?
      flash[:error] = _("You must select at least one Provider Account to remove.")
    else
      ProviderAccount.find(params[:accounts_selected]).each do |provider_account|
        if @pool_family.provider_accounts.delete provider_account
          removed << provider_account.name
        else
          not_removed << provider_account.name
        end
      end
      unless removed.empty?
        flash[:notice] = "#{_("These Provider Accounts were removed")}: #{removed.join(', ')}"
      end
      unless not_removed.empty?
        flash[:error] = "#{_("Could not remove these Provider Accounts")}: #{not_removed.join(', ')}"
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
      {:name => _("Name"), :sort_attr => :name},
      {:name => _("Quota Used"), :sort_attr => :name},
      {:name => _("Quota Limit"), :sort_attr => :name},
    ]
  end

  def load_pool_families
    @pool_families = PoolFamily.list_for_user(current_session, current_user,
                                              Privilege::VIEW).
      order(sort_column(PoolFamily) + ' ' + sort_direction)
  end

  def load_pool_family_tabs
    @tabs = [{:name => _("Pools"),:view => 'pools', :id => 'pools', :count => @pool_family.pools.count},
             {:name => _("Accounts"), :view => 'provider_accounts', :id => 'provider_accounts', :count => @pool_family.provider_accounts.count},
             {:name => _("Images"), :view => 'images', :id => 'images', :count => @all_images.count},
    ]
    add_permissions_tab(@pool_family)
    details_tab_name = params[:details_tab].blank? ? 'pools' : params[:details_tab]
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase
    @view = @details_tab[:view]

    case
    when @view == 'pools'
      @pools_header = [
        {:name => _("Pool Name"), :sortable => false},
        {:name => _("Deployments"), :class => 'center', :sortable => false},
        {:name => _("Total Inst."), :class => 'center', :sortable => false},
        {:name => _("Pending Inst."), :class => 'center', :sortable => false},
        {:name => _("Failed Inst."), :class => 'center', :sortable => false},
        {:name => _("Quota Used"), :class => 'center', :sortable => false},
        {:name => _("Active Inst."), :class => 'center', :sortable => false},
        {:name => _("Available Inst."), :class => 'center', :sortable => false},
        {:name => '', :sortable => false}
      ]
    when @view == 'images'
      @header = [
        { :name => 'checkbox', :class => 'checkbox', :sortable => false },
        { :name => _("Name"), :sort_attr => :name },
        { :name => _("OS"), :sort_attr => :name },
        { :name => _("OS Version"), :sort_attr => :name },
        { :name => _("Architecture"), :sort_attr => :name },
        { :name => _("Last Rebuild"), :sortable => false },
      ]
    end

  end
end
