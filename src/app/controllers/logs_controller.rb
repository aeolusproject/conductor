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

    params[:view] = "filter" if params[:view].nil?
    @view = params[:view]

    load_options
    load_events
    load_headers unless @view == "pretty"
    generate_graph if @view == "pretty"

    respond_to do |format|
      format.html { @partial = filter_view? ? 'filter_view' : 'pretty_view' }
      format.js { render :partial => filter_view? ?
        'filter_view' :
        'pretty_view' }
    end
  end

  def filter
    redirect_to_original({ "source_type" => params[:source_type],
                           "pool_select" => params[:pool_select],
                           "provider_select" => params[:provider_select],
                           "owner_id" => params[:owner_id],
                           "state" => params[:state],
                           "from_date" => params[:from_date],
                           "to_date" => params[:to_date],
                           "order" => params[:order],
                           "group" => params[:group],
                           "view" => params[:view] })
  end

  def export_logs
    load_events
    load_headers

    csvm = get_csv_class
    csv_string = csvm.generate(:col_sep => ";", :row_sep => "\r\n") do |csv|
      csv << @header.map {|header| header[:name].capitalize }

      unless @events.nil?
        @events.each do |event|
          source = event.source
          provider_account = source.nil? ? nil : source.provider_account
          csv << [ event.event_time.strftime("%d-%b-%Y %H:%M:%S"),
                   source.nil? ? _("N/A") : source.name,
                   source.nil? ? _("N/A") : source.state,
                   source.nil? ?
                     _("N/A") :
                     source.pool_family.name + "/" + source.pool.name,
                   provider_account.nil? ?
                     _("N/A") :
                     provider_account.provider.name + "/" +
                       provider_account.name,
                   source.nil? ?
                     _("N/A") :
                     source.owner.username,
                   event.summary ]
        end
      end
    end

    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => "export.csv")
  end

  protected

  def load_events
    @source_type = params[:source_type].nil? ? "" : params[:source_type]
    @pool_select = params[:pool_select].nil? ? "" : params[:pool_select]
    @provider_select =
      params[:provider_select].nil? ? "" : params[:provider_select]
    @owner_id = params[:owner_id].nil? ? "" : params[:owner_id]
    @state = params[:state].nil? ? "" : params[:state]
    @order = params[:order].nil? ? _("Time") : params[:order]
    @from_date = params[:from_date].nil? ? Date.today - 7.days :
      Date.civil(params[:from_date][:year].to_i,
                 params[:from_date][:month].to_i,
                 params[:from_date][:day].to_i)
    @to_date = params[:to_date].nil? ? Date.today :
      Date.civil(params[:to_date][:year].to_i,
                 params[:to_date][:month].to_i,
                 params[:to_date][:day].to_i)

    if @to_date < @from_date
      @events = []
      @paginated_events = []
      flash[:error] = _("'From date' cannot be after 'To date'")
      return
    end

    # modify parameters for pretty view
    if @view == "pretty"
      @state = ""
      @pool_select = ""
      @provider_select = ""
      @owner_id = ""
      @order = _("Time")
      @source_type = "Deployment" if @source_type == ""
    end

    if @source_type.present?
      conditions = ["event_time between ? and ? and source_type = ?",
                    @from_date.to_datetime.beginning_of_day,
                    @to_date.to_datetime.end_of_day,
                    @source_type]
    else
      conditions = ["event_time between ? and ? and source_type in (?)",
                    @from_date.to_datetime.beginning_of_day,
                    @to_date.to_datetime.end_of_day,
                   ["Deployment", "Instance"]]
    end

    @events = Event.unscoped.find(:all,
                                  :include =>
                                  {:source => [:pool_family, :pool, :owner]},
                                  :conditions => conditions,
                                  :order => "event_time asc"
                                  )
    deployments = Deployment.unscoped.list_for_user(current_session,
                                                    current_user,
                                                    Privilege::VIEW)
    instances = Instance.unscoped.list_for_user(current_session,
                                                current_user, Privilege::VIEW)

    pool_option, pool_option_id = @pool_select.split(":")
    provider_option, provider_option_id = @provider_select.split(":")

    @events = @events.find_all{|event|
      source = event.source
      source_class = source.class.name

      # permission checks
      next if source_class == "Deployment" and !deployments.include?(source)
      next if source_class == "Instance" and !instances.include?(source)

      # filter by user
      next if @owner_id.present? && source.owner_id.to_s != @owner_id

      # filter by state
      if @state.present?
        next if source.state != @state
      end

      # filter by pool
      if @pool_select.present?
        next if (pool_option == "pool_family" &&
                 source.pool_family_id.to_s != pool_option_id)
        next if pool_option == "pool" && source.pool_id.to_s != pool_option_id
      end

      # filter by provider
      if @provider_select.present?
        event_provider_account = source.provider_account
        next if event_provider_account.nil?
        next if (provider_option == "provider" &&
                 source.provider_account.provider.id.to_s != provider_option_id)
        next if (provider_option == "provider_account" &&
                 source.provider_account.id.to_s != provider_option_id)
      end

      true
    }

    case @order
    when _("Deployment/Instance")
      @events = @events.sort_by {|event|
        (event.source.nil? ? "" : event.source.name.downcase)}
    when _("State")
      @events = @events.sort_by {|event|
        (event.source.nil? ? "" :
         (event.source.state.nil? ? "" : event.source.state.downcase))}
    when _("Pool")
      @events = @events.sort_by {|event|
        (event.source.nil? ? "" : event.source.pool_family.name.downcase)}
    when _("Provider")
      @events = @events.sort_by {|event|
        source = event.source
        (source.nil? ? "" :
         (source.provider_account.nil? ? "" :
          source.provider_account.name.downcase))}
    when _("Owner")
      @events = @events.sort_by {|event|
        (event.source.nil? ? "" : event.source.owner.username.downcase)}
    end

    @paginated_events = paginate_collection(@events, params[:page], PER_PAGE)
  end

  def load_options
    if @view == "pretty"
      @source_type_options = [[_("Deployment"), "Deployment"],
                              [_("Instance"), "Instance"]]
      @group_options = [[_("All"), ""],
                        _("Pool"),
                        _("Provider"),
                        _("Owner")]
    else
      @source_type_options = [[_("All Event Types"), ""],
                              [_("Deployment"), "Deployment"],
                              [_("Instance"), "Instance"]]
      @pool_options = [[_("All Pools"), ""]]
      PoolFamily.list_for_user(current_session, current_user, Privilege::VIEW).
        find(:all, :include => :pools, :order => "pool_families.name",
             :select => ["id", "name"]).each do |pool_family|
        @pool_options << [pool_family.name,
                          "pool_family:" + pool_family.id.to_s]
        @pool_options += pool_family.pools.
          map{|x| [" -- " + x.name, "pool:" + x.id.to_s]}
      end
      @provider_options = [[_("All Providers"), ""]]
      Provider.list_for_user(current_session, current_user, Privilege::VIEW).
        find(:all, :include => :provider_accounts, :order => "providers.name",
             :select => ["id", "name"]).each do |provider|
        @provider_options << [provider.name, "provider:" + provider.id.to_s]
        @provider_options += provider.provider_accounts.
          map{|x| [" -- " + x.name, "provider_account:" + x.id.to_s]}
      end
      @owner_options = [[_("All Users"), ""]] +
        User.find(:all, :order => "username",
                  :select => ["id", "username"]).map{|x| [x.username, x.id]}
      @order_options = [_("Time"),
                        _("Deployment/Instance"),
                        _("State"),
                        _("Pool"),
                        _("Provider"),
                        _("Owner")]
      @state_options = ([[_("All States"), ""]] +
                        Deployment::STATES + Instance::STATES).uniq
    end
  end

  def load_headers
    @header = [
      { :name => _("Time"), :sortable => false },
      { :name => _("Deployment/Instance"), :sortable => false },
      { :name => _("State"), :sortable => false },
      { :name => _("Pool"), :sortable => false },
      { :name => _("Provider"), :sortable => false },
      { :name => _("Owner"), :sortable => false },
      { :name => _("Summary"), :sortable => false },
      { :name => "", :sortable => false },
    ]
  end

  def generate_graph
    @group = params[:group].nil? ? "" : params[:group]

    start_code = (@source_type == 'Deployment' ? 'first_running' : 'running')
    end_code = (@source_type == 'Deployment' ? 'all_stopped' : 'stopped')

    initial_conditions = ["exists (select 1 from events
                                   where source_type = '" + @source_type + "'
                                   and source_id = " + @source_type + "s.id
                                   and status_code = '" + start_code + "'
                                   and event_time <= ?)
                           and not exists (select 1 from events
                                      where source_type = '" + @source_type + "'
                                      and source_id = " + @source_type + "s.id
                                      and status_code = '" + end_code + "'
                                      and event_time <= ?)",
                          @from_date.to_datetime.beginning_of_day,
                          @from_date.to_datetime.beginning_of_day]

    if @source_type == "Deployment"
      @initial_sources = Deployment.unscoped.
        list_for_user(current_session, current_user, Privilege::VIEW).
        find(:all, :conditions => initial_conditions)
    else
      @initial_sources = Instance.unscoped.
        list_for_user(current_session, current_user, Privilege::VIEW).
        find(:all, :conditions => initial_conditions)
    end

    @datasets = ChartDatasets.new(@from_date, @to_date)
    @datasets.increment_count("All",@initial_sources.count)

    if @group_options.include?(@group)
      @initial_sources.each do |source|
        label = get_source_label(source, @group)
        @datasets.increment_count(label,1)
      end
    end

    # these will be needed to handle the case where a source stops without
    # ever going into the running state
    start_conditions = ["source_type = ? and status_code = ?",
                        @source_type, start_code]
    start_events = Event.unscoped.find(:all,
                                       :conditions => start_conditions)

    @datasets.initialize_datasets

    @events.each do |event|
      event_timestamp = event.event_time.to_i * 1000

      if event.status_code == start_code ||
          (event.status_code == end_code &&
           start_events.any? {|s|
             s.source_id == event.source_id &&
             s.event_time <= event.event_time
           }
           )
        increment = (event.status_code == end_code) ? -1 : 1

        @datasets.add_dataset_point("All", event_timestamp, increment)

        if @group_options.include?(@group)
          label = get_source_label(event.source, @group)
          @datasets.add_dataset_point(label, event_timestamp, increment)
        end
      end
    end

    @datasets.finalize_datasets
  end

  def get_source_label(source, label_type)
    label = "Unknown"
    if !source.nil?
      case label_type
      when _("Pool")
        label = source.pool.name unless source.pool.nil?
      when _("Provider")
        label = source.provider_account.name unless source.provider_account.nil?
      when _("Owner")
        label = source.owner.name unless source.owner.nil?
      end
    end

    label
  end
end
