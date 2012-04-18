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

class LogsController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    save_breadcrumb(logs_path)

    load_headers
    load_options
    load_logs
    respond_to do |format|
      format.html
    end
  end

  def filter
    redirect_to_original({"source_type" => params[:source_type], "pool_select" => params[:pool_select], "provider_select" => params[:provider_select], "owner_id" => params[:owner_id], "state" => params[:state]})
  end

  protected

  def load_logs
    @source_type = params[:source_type].nil? ? "" : params[:source_type]
    @pool_select = params[:pool_select].nil? ? "" : params[:pool_select]
    @provider_select = params[:provider_select].nil? ? "" : params[:provider_select]
    @owner_id = params[:owner_id].nil? ? "" : params[:owner_id]
    @state = params[:state].nil? ? "" : params[:state]

    conditions = []
    if @source_type.present?
      conditions += ["source_type = ?", @source_type]
    end

    @events = Event.unscoped.find(:all,
                             :include => {:source => [:pool_family, :pool, :owner]},
                             :conditions => conditions
                             )
    deployments = Deployment.unscoped.list_for_user(current_user, Privilege::VIEW)
    instances = Instance.unscoped.list_for_user(current_user, Privilege::VIEW)

    pool_option, pool_option_id = @pool_select.split(":")
    provider_option, provider_option_id = @provider_select.split(":")

    @events = @events.find_all{|event|
      source_class = event.source.class.name

      # permission checks
      next if source_class == "Deployment" and !deployments.include?(event.source)
      next if source_class == "Instance" and !instances.include?(event.source)

      # filter by user
      next if @owner_id.present? && event.source.owner_id.to_s != @owner_id

      # filter by state
      if @state.present?
        event_state = (source_class == "Deployment" ? event.source.status.to_s : event.source.state)
        next if event_state != @state
      end

      # filter by pool
      if @pool_select.present?
        next if pool_option == "pool_family" && event.source.pool_family_id.to_s != pool_option_id
        next if pool_option == "pool" && event.source.pool_id.to_s != pool_option_id
      end

      # filter by provider
      if @provider_select.present?
        event_provider_account = event.source.provider_account
        next if event_provider_account.nil?
        next if provider_option == "provider" && event.source.provider_account.provider.id.to_s != provider_option_id
        next if provider_option == "provider_account" && event.source.provider_account.id.to_s != provider_option_id
      end

      true
    }

    @paginated_events = paginate_collection(@events, params[:page], PER_PAGE)
  end

  def load_options
    @source_type_options = [[t('logs.options.default_event_types'), ""], t('logs.options.deployment_event_type'), t('logs.options.instance_event_type')]
    @state_options = [[t('logs.options.default_states'), ""]] + Instance::STATES
    @pool_options = [[t('logs.options.default_pools'), ""]]
    PoolFamily.list_for_user(current_user, Privilege::VIEW).find(:all, :include => :pools, :order => "name", :select => ["id", "name"]).each do |pool_family|
      @pool_options << [pool_family.name, "pool_family:" + pool_family.id.to_s]
      @pool_options += pool_family.pools.map{|x| [" -- " + x.name, "pool:" + x.id.to_s]}
    end
    @provider_options = [[t('logs.options.default_providers'), ""]]
    Provider.list_for_user(current_user, Privilege::VIEW).find(:all, :include => :provider_accounts, :order => "name", :select => ["id", "name"]).each do |provider|
      @provider_options << [provider.name, "provider:" + provider.id.to_s]
      @provider_options += provider.provider_accounts.map{|x| [" -- " + x.name, "provider_account:" + x.id.to_s]}
    end
    @owner_options = [[t('logs.options.default_users'), ""]] + User.find(:all, :order => "login", :select => ["id", "login"]).map{|x| [x.login, x.id]}
  end

  def load_headers
    @header = [
      { :name => t('logs.index.event_time'), :sortable => false },
      { :name => t('logs.index.deployment'), :sortable => false },
      { :name => t('logs.index.state'), :sortable => false },
      { :name => t('logs.index.pool'), :sortable => false },
      { :name => t('logs.index.provider'), :sortable => false },
      { :name => t('logs.index.owner'), :sortable => false },
      { :name => t('logs.index.summary'), :sortable => false },
      { :name => "", :sortable => false },
    ]
  end
end
