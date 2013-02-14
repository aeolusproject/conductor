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

class ProvidersController < ApplicationController
  before_filter :require_user
  before_filter :load_providers, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter :load_providers_types, :only => [:new, :edit, :update, :create]
  before_filter ResourceLinkFilter.new({ :provider => :provider_type }),
                :only => [:create, :update]

  def index
    @from_date = params[:from_date].nil? ? Date.today - 7.days :
      Date.civil(params[:from_date][:year].to_i,
                 params[:from_date][:month].to_i,
                 params[:from_date][:day].to_i)
    @to_date = params[:to_date].nil? ? Date.today :
      Date.civil(params[:to_date][:year].to_i,
                 params[:to_date][:month].to_i,
                 params[:to_date][:day].to_i)

    if @to_date < @from_date
      flash[:error] = _('\'From date\' cannot be after \'To date\'')
    end

    load_headers
    statistics

    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.xml { render :partial => 'list.xml' , :locals => { :minimal => params[:minimal] }}
    end
  end

  def filter
    redirect_to_original({ "from_date" => params[:from_date],
                           "to_date" => params[:to_date] })
  end

  def new
    require_privilege(Privilege::CREATE, Provider)
    @provider = Provider.new
    @provider.url = Provider::DEFAULT_DELTACLOUD_URL
    @provider.provider_type = ProviderType.find_by_deltacloud_driver('ec2')
    @title = _('New Provider')
  end

  def edit
    @provider = Provider.find(params[:id])
    @title = _('Cloud Providers')
    # requiring VIEW rather than MODIFY since edit doubles as the 'show' page
    # here -- actions must be hidden explicitly in template
    require_privilege(Privilege::VIEW, @provider)

    if params.delete :test_provider
      test_connection(@provider)
    end

    respond_to do |format|
      format.html
      format.json { render :json => @provider }
    end

  end

  def show
    @provider = Provider.find(params[:id])
    require_privilege(Privilege::VIEW, @provider)

    @alerts = provider_alerts(@provider)
    load_provider_tabs

    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane'
        else
          render :partial => @view
        end
      end
      format.xml { render :partial => 'detail', :locals => { :provider => @provider } }
    end
  end

  def create
    @title = _('New Provider')
    require_privilege(Privilege::CREATE, Provider)
    @provider = Provider.new(params[:provider])

    if @provider.save
      @provider.assign_owner_roles(current_user)
      respond_to do |format|
        format.html do
          flash[:notice] = _('Provider added.')
          redirect_to provider_path(@provider)
        end
        format.xml do
          render :partial => 'detail',
                 :status => :created,
                 :locals => { :provider => @provider }
        end
      end
    else
      respond_to do |format|
        format.html do
          render :action => "new"
        end
        format.xml do
          render :template => 'api/validation_error',
                 :locals => { :errors => @provider.errors },
                 :status => :unprocessable_entity
        end
      end
    end
  rescue Errno::EACCES
    Provider.skip_callback :save, :check_name
    @provider.save
    @provider.assign_owner_roles(current_user)
    respond_to do |format|
      format.html do
        flash[:notice] = _('Provider added.')
        flash[:warning] = _('Cannot check if provider name is right. Please check config file')
        redirect_to provider_path(@provider)
      end
    end
  end

  def update
    @provider = Provider.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider)

    @provider.assign_attributes(params[:provider])
    provider_disabled = @provider.enabled_changed? && !@provider.enabled

    if provider_disabled
      disable_provider
      return
    end

    if @provider.save
      @provider.update_availability
      respond_to do |format|
        format.html do
          flash[:notice] = _('Provider updated.')
          redirect_to provider_path(@provider)
        end
        format.xml { render :partial => 'detail', :locals => { :provider => @provider } }
      end
    else
      # we reset 'enabled' attribute to real state
      # if save failed
      @provider.reset_enabled!
      respond_to do |format|
        format.html do
          load_provider_tabs
          @alerts = provider_alerts(@provider)
          render :action => "edit"
        end
        format.xml do
          render :template => 'api/validation_error',
                 :locals => { :errors => @provider.errors },
                 :status => :unprocessable_entity
        end
      end
    end
  rescue Errno::EACCES
    Provider.skip_callback :save, :check_name
    @provider.save
    respond_to do |format|
      format.html do
        flash[:notice] = _('Provider updated.')
        flash[:warning] = _('Cannot check if provider name is right. Please check config file')
        redirect_to provider_path(@provider)
      end
    end
  end

  def destroy
    provider = Provider.find(params[:id])
    require_privilege(Privilege::MODIFY, provider)

    respond_to do |format|
      if provider.safe_destroy
        session[:current_provider_id] = nil
        format.html do
          flash[:notice] = _('Provider has been deleted.')
          redirect_to providers_path
        end
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.html do
          flash[:error] = _('Provider was not deleted: %s') % provider.errors.full_messages.join(', ')
          redirect_to providers_path
        end
        # FIXME: what to return in body of response, if anything?
        format.xml do
          raise(Aeolus::Conductor::API::Error.new(500, error))
        end
      end
    end
  end

  protected

  def test_connection(provider)
    @provider.errors.clear
    if @provider.update_availability
      flash.now[:notice] = _('Successfully connected to Provider')
    else
      flash.now[:warning] = _('Failed to connect to Provider')
      @provider.errors.add :url
    end
  end

  def load_providers
    @providers = Provider.includes(:provider_type).list_for_user(current_session, current_user,
                                        Privilege::VIEW).order("providers.name")
  end

  def disable_provider
    @instances_to_terminate = @provider.instances_to_terminate
    if @instances_to_terminate.any? and not params[:terminate]
      render :action => "confirm_terminate"
      return
    end

    res = @provider.disable(current_user)
    if res[:failed_to_stop].present?
      flash[:error] = {
        :summary => _('Provider was not disabled. Failed to stop following instances:'),
        :failures => res[:failed_to_stop]
      }
    elsif res[:failed_to_terminate].present?
      flash[:error] = {
        :summary => _('Provider was not disabled. Failed to change status to \'stopped\' for following instances:'),
        :failures => res[:failed_to_terminate].map {|i| i.name}
      }
    else
      flash[:notice] = _('Provider disabled.')
    end
    redirect_to edit_provider_path(@provider)
  end

  def provider_alerts(provider)
    alerts = []

    # Quota Alerts
    provider.provider_accounts.each do |provider_account|
      unless provider_account.quota.maximum_running_instances == nil
        if provider_account.quota.maximum_running_instances < provider_account.quota.running_instances
          alerts << {
            :class => "critical",
            :subject => "#{_('Quota')}",
            :alert_type => "#{_('Account Quota Exceeded')}",
            :path => edit_provider_provider_account_path(@provider,provider_account),
            :description => _('Quota limit of running Instances for %s account has been exceeded.') % provider_account.name,
            :account_id => provider_account.id
          }
        end

        if (70..100) === provider_account.quota.percentage_used.round
          alerts << {
            :class => "warning",
            :subject => "#{_('Quota')}",
            :alert_type => "#{provider_account.quota.percentage_used.round}% #{_('Account Quota Reached')}",
            :path => provider_provider_account_path(@provider,provider_account),
            :description => "#{provider_account.quota.percentage_used.round}% "+ _('of Quota limit for running Instances for %s account has been reached.') % provider_account.name,
            :account_id => provider_account.id
          }
        end
      end
    end

    return alerts
  end

  def load_providers_types
    provider_types = ProviderType.all.map do |type|
      begin
        label = I18n.translate!("providers.form.x_deltacloud_provider.#{type.deltacloud_driver}")
      rescue
      end

      { :id => type.id,
        :label => label,
        :name => type.name }
    end
    @labeled_provider_types = provider_types.select {|type| type[:label]}
    @provider_type_options = provider_types.map {|type| [type[:name], type[:id]]}
  end

  def load_provider_tabs
    @realms = @provider.provider_realms.apply_filters(:preset_filter_id => params[:provider_realms_preset_filter], :search_filter => params[:provider_realms_search])
    #TODO add links to real data for history,properties,permissions
    @tabs = [{ :name => _('Properties'),
               :view => 'properties',
               :id => 'properties' },
             { :name => _('Accounts'),
               :view => 'provider_accounts/list',
               :id => 'accounts',
               :count => @provider.provider_accounts.count },
             { :name => _('Provider Realms'),
               :view => 'provider_realms/list',
               :id => 'realms',
               :count => @realms.count },
             { :name => _('Hardware Profiles'),
               :view => 'hardware_profiles',
               :id => 'hardware_profiles',
               :count => @provider.hardware_profiles.count}
    ]
    add_permissions_tab(@provider, "edit_")
    details_tab_name = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    details_tab_name = 'properties' unless
      ['accounts', 'realms', 'hardware_profiles', 'permissions'].include?(details_tab_name)

    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase

    if @details_tab[:id] == 'accounts'
      @provider_accounts = @provider.provider_accounts.
        apply_filters(:preset_filter_id =>
                        params[:provider_accounts_preset_filter],
                      :search_filter => params[:provider_accounts_search]).
        list_for_user(current_session, current_user, Privilege::VIEW)
    elsif @details_tab[:id] == 'hardware_profiles'
      @hardware_profiles = @provider.hardware_profiles
    end
    #@permissions = @provider.permissions if @details_tab[:id] == 'roles'

    @view = @details_tab[:view]
  end

  def load_headers
    @header = [
      { :name => _('Provider Name'), :class => 'center',
        :sortable => false },
      { :name => _('Provider Type'), :class => 'center',
        :sortable => false },
      { :name => _('Running Instances (Current)'), :class => 'center',
        :sortable => false },
      { :name => _('Pending (Current)'), :class => 'center',
        :sortable => false },
      { :name => _('Errors (Current)'), :class => 'center',
        :sortable => false },
      { :name => _('Running (Historical)'), :class => 'center',
        :sortable => false },
      { :name => _('Errors (Historical)'), :class => 'center',
        :sortable => false },
      { :name => _('Enabled'), :class => 'center',
        :sortable => false },
    ]
  end

  def statistics
    @statistics = Hash.new
    @providers.each do |provider|
      @statistics[provider.id] = {
        "running_instances" => 0,
        "pending_instances" => 0,
        "error_instances" => 0,
        "historical_running_instances" => 0,
        "historical_error_instances" => 0,
      }
    end

    # Queries are NOT permissioned by instance, as info is
    # used purely for statistical purposes.

    # current instances
    provider_counts = ProviderAccount.joins(:instances).
      merge(Instance.scoped).
      select("provider_id, state, count(*) as count").
      where(:provider_id => @providers.map{|provider| provider.id}).
      group("provider_id, state")

    provider_counts.each do |provider_count|
      provider_id = provider_count["provider_id"]
      state = provider_count["state"]
      count = provider_count["count"]

      if Instance::FAILED_STATES.include?(state)
        @statistics[provider_id]["error_instances"] += count.to_i
      elsif [Instance::STATE_RUNNING, Instance::STATE_SHUTTING_DOWN].
               include?(state)
        @statistics[provider_id]["running_instances"] += count.to_i
      elsif [Instance::STATE_NEW, Instance::STATE_PENDING].
               include?(state)
        @statistics[provider_id]["pending_instances"] += count.to_i
      end
    end

    # instances that were running between historical date range
    historical_running_provider_counts = ProviderAccount.joins(:instances).
      merge(Instance.unscoped).
      select("provider_id, state, count(*) as count").
      where(:provider_id => @providers.map{|provider| provider.id}).
      where("time_last_running <= :to_date and
             (time_last_stopped is null
              or time_last_stopped >= :from_date)",
            :to_date => @to_date.to_datetime.end_of_day,
            :from_date => @from_date.to_datetime.beginning_of_day
            ).
      group("provider_id, state")

    historical_running_provider_counts.each do |provider_count|
      provider_id = provider_count["provider_id"]
      count = provider_count["count"]

      @statistics[provider_id]["historical_running_instances"] += count.to_i
    end

    # instances that threw an error between historical date range
    historical_error_provider_counts = ProviderAccount.joins(:instances).
      merge(Instance.unscoped).
      select("provider_id, count(*) as count").
      where(:provider_id => @providers.map{|provider| provider.id}).
      where("instances.state" => Instance::FAILED_STATES).
      where("instances.updated_at between :from_date and :to_date",
            :states => Instance::FAILED_STATES,
            :to_date => @to_date.to_datetime.end_of_day,
            :from_date => @from_date.to_datetime.beginning_of_day
            ).
      group("provider_id")

    historical_error_provider_counts.each do |provider_count|
      provider_id = provider_count["provider_id"]
      count = provider_count["count"]

      @statistics[provider_id]["historical_error_instances"] += count.to_i
    end

    # all running instances during historical date range
    historical_instances = Instance.unscoped.
      find(:all,
           :conditions => ["time_last_running <= ? and
                             (time_last_stopped is null
                              or time_last_stopped >= ?)",
                           @to_date.to_datetime.end_of_day,
                           @from_date.to_datetime.beginning_of_day],
           :include => {:provider_account => [:provider]}
           )

    @datasets = ChartDatasets.new(@from_date, @to_date)
    events = Array.new

    historical_instances.each do |instance|
      provider_account = instance.provider_account

      if check_privilege(Privilege::VIEW, provider_account)
        label = provider_account.nil? ?
                  'Unknown' :
                  provider_account.provider.name +
                  " (" + provider_account.name + ")"

        # see if instance started before from_date
        if instance.time_last_running <= @from_date.to_datetime.beginning_of_day
          @datasets.increment_count(label,1)
          @datasets.increment_count("All",1)
        else
          events << {
            "time" => instance.time_last_running,
            "label" => label,
            "increment" => 1
          }
        end

        if !instance.time_last_stopped.nil? &&
            instance.time_last_stopped >= instance.time_last_running &&
            instance.time_last_stopped <= @to_date.to_datetime.end_of_day
          events << {
            "time" => instance.time_last_stopped,
            "label" => label,
            "increment" => -1
          }
        end
      end
    end

    @datasets.initialize_datasets

    events.sort_by {|event| event["time"]}.each do |event|
      timestamp = event["time"].to_i * 1000
      increment = event["increment"]

      [ event["label"], "All" ].each { |label|
        @datasets.add_dataset_point(label,timestamp,increment)
      }
    end

    @datasets.finalize_datasets
  end
end
