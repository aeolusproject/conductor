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
      flash[:error] = t('logs.flash.error.date_range')
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
    @title = t("providers.new.new_provider")
  end

  def edit
    @provider = Provider.find(params[:id])
    @title = t 'cloud_providers'
    session[:current_provider_id] = @provider.id
    # requiring VIEW rather than MODIFY since edit doubles as the 'show' page
    # here -- actions must be hidden explicitly in template
    require_privilege(Privilege::VIEW, @provider)

    @alerts = provider_alerts(@provider)

    if params.delete :test_provider
      test_connection(@provider)
    end

    load_provider_tabs

    respond_to do |format|
      format.html
      format.js { render :partial => @view }
      format.json { render :json => @provider }
    end

  end

  def show
    @provider = Provider.find(params[:id])
    @realm_names = @provider.provider_realms.collect { |r| r.name }

    require_privilege(Privilege::VIEW, @provider)
    @tab_captions = [t("properties"), t('hw_profiles'), t('realm_s'), t("provider_accounts.index.provider_accounts"), t('services'), t('history'), t('permissions')]
    @details_tab = params[:details_tab].blank? ? t("properties") : params[:details_tab]
    @details_tab = 'properties' unless ['properties', 'hw_profiles', 'realms',
                                        'provider_accounts', 'services', 'history',
                                        'permissions'].include?(@details_tab)

    if params.delete :test_provider
      test_connection(@provider)
    end

    respond_to do |format|
      format.html { render :action => 'show' }
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.xml { render :partial => 'detail', :locals => { :provider => @provider } }
    end
  end

  def create
    @title = t("providers.new.new_provider")
    require_privilege(Privilege::CREATE, Provider)

    if params[:provider].has_key?(:provider_type_deltacloud_driver)
      provider_type = params[:provider].delete(:provider_type_deltacloud_driver)
      provider_type = ProviderType.find_by_deltacloud_driver(provider_type)
      params[:provider][:provider_type_id] = provider_type.id
    end


    @provider = Provider.new(params[:provider])

    begin
      if @provider.save
        @provider.assign_owner_roles(current_user)
        respond_to do |format|
          format.html do
            flash[:notice] = t"providers.flash.notice.added"
            redirect_to edit_provider_path(@provider)
          end
          format.xml { render :partial => 'detail',
                              :status => :created,
                              :locals => { :provider => @provider } }
        end
      else
        respond_to do |format|
          format.html do
            flash[:warning] = t"providers.flash.error.not_added"
            render :action => "new"
          end
          format.xml { render :template => 'api/validation_error',
                              :locals => { :errors => @provider.errors },
                              :status => :unprocessable_entity }
        end
      end
    rescue Errno::EACCES
      Provider.skip_callback :save, :check_name
      @provider.save
      @provider.assign_owner_roles(current_user)
      respond_to do |format|
        format.html do
          flash[:notice] = t"providers.flash.notice.added"
          flash[:warning] = t"providers.flash.warning.check_config_file"
          redirect_to edit_provider_path(@provider)
        end
      end
    end

  end

  def update
    @provider = Provider.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider)
    @provider.attributes = params[:provider]
    provider_disabled = @provider.enabled_changed? && !@provider.enabled

    if provider_disabled
      disable_provider
      return
    end

    begin
      if @provider.save
        @provider.update_availability
        respond_to do |format|
          format.html do
            flash[:notice] = t"providers.flash.notice.updated"
            redirect_to edit_provider_path(@provider)
          end
          format.xml { render :partial => 'detail', :locals => { :provider => @provider } }
        end
      else
        # we reset 'enabled' attribute to real state
        # if save failed
        @provider.reset_enabled!
        respond_to do |format|
          format.html do
            unless @provider.connect
              flash.now[:warning] = t"providers.flash.warning.connect_failed"
            else
              flash[:error] = t"providers.flash.error.not_updated"
            end
            load_provider_tabs
            @alerts = provider_alerts(@provider)
            render :action => "edit"
          end
          format.xml { render :template => 'api/validation_error',
                              :locals => { :errors => @provider.errors },
                              :status => :unprocessable_entity }
        end
      end
    rescue Errno::EACCES
      Provider.skip_callback :save, :check_name
      @provider.save
      respond_to do |format|
        format.html do
          flash[:notice] = t"providers.flash.notice.updated"
          flash[:warning] = t"providers.flash.warning.check_config_file"
          redirect_to edit_provider_path(@provider)
        end
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
          flash[:notice] = t("providers.flash.notice.deleted")
          redirect_to providers_path
        end
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.html do
          flash[:error] = t("providers.flash.error.not_deleted_with_err",
                            :err => provider.errors.full_messages.join(', '))
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
      flash.now[:notice] = t"providers.flash.notice.connected"
    else
      flash.now[:warning] = t"providers.flash.warning.connect_failed"
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
        :summary => t("providers.flash.warning.not_stopped_instances"),
        :failures => res[:failed_to_stop]
      }
    elsif res[:failed_to_terminate].present?
      flash[:error] = {
        :summary => t("providers.flash.warning.not_terminated_instances"),
        :failures => res[:failed_to_terminate].map {|i| i.name}
      }
    else
      flash[:notice] = t"providers.flash.notice.disabled"
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
            :subject => "#{t'providers.alerts.subject.quota'}",
            :alert_type => "#{t'providers.alerts.alert_type.quota_exceeded'}",
            :path => edit_provider_provider_account_path(@provider,provider_account),
            :description => "#{t'providers.alerts.description.quota_exceeded', :name => "#{provider_account.name}"}",
            :account_id => provider_account.id
          }
        end

        if (70..100) === provider_account.quota.percentage_used.round
          alerts << {
            :class => "warning",
            :subject => "#{t'providers.alerts.subject.quota'}",
            :alert_type => "#{provider_account.quota.percentage_used.round}% #{t'providers.alerts.alert_type.quota_reached'}",
            :path => provider_provider_account_path(@provider,provider_account),
            :description => "#{provider_account.quota.percentage_used.round}% #{t'providers.alerts.description.quota_reached', :name => "#{provider_account.name}" }",
            :account_id => provider_account.id
          }
        end
      end
    end

    return alerts
  end

  def load_providers_types
    available_providers = ["Mock","Amazon EC2","RHEV-M","VMware vSphere","Rackspace","Openstack"]
    provider_types = ProviderType.where(:name => available_providers).map do |type|
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
    @tabs = [{:name => t('connectivity'), :view => 'edit', :id => 'connectivity'},
             {:name => t('accounts'), :view => 'provider_accounts/list', :id => 'accounts', :count => @provider.provider_accounts.count},
             {:name => t('provider_realms.provider_realms'), :view => 'provider_realms/list', :id => 'realms', :count => @realms.count},
             #{:name => 'Roles & Permissions', :view => @view, :id => 'roles', :count => @provider.permissions.count},
    ]
    add_permissions_tab(@provider, "edit_")
    details_tab_name = params[:details_tab].blank? ? 'connectivity' : params[:details_tab]
    details_tab_name = 'connectivity' unless
      ['connectivity', 'accounts', 'realms', 'permissions'].include?(details_tab_name)
    @details_tab = @tabs.find {|t| t[:id] == details_tab_name} || @tabs.first[:name].downcase

    if @details_tab[:id] == 'accounts'
      @provider_accounts = @provider.provider_accounts.
        apply_filters(:preset_filter_id =>
                        params[:provider_accounts_preset_filter],
                      :search_filter => params[:provider_accounts_search]).
        list_for_user(current_session, current_user, Privilege::VIEW)
    end
    #@permissions = @provider.permissions if @details_tab[:id] == 'roles'

    @view = @details_tab[:view]
  end

  def load_headers
    @header = [
      { :name => t('providers.index.provider_name'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.provider_type'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.running_instances'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.pending_instances'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.error_instances'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.historical_running_instances'), :class => 'center',
                 :sortable => false },
      { :name => t('providers.index.historical_error_instances'), :class => 'center',
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
