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

class InstancesController < ApplicationController
  before_filter :require_user
  before_filter :load_instance, :only => [:show, :key, :edit, :update, :stop, :reboot]
  before_filter :set_view_vars, :only => [:show, :index, :export_events]
  before_filter :check_inaccessible_instances, :only => [:stop, :multi_stop]

  def index
    @params = params
    @title = _("Instances")
    save_breadcrumb(instances_path(:viewstate => viewstate_id))
    load_instances

    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.json { render :json => @instances.map{ |instance| view_context.instance_for_mustache(instance) } }
      format.xml { @deployment = @instances.first.deployment if params[:deployment_id] }
    end
  end

  def show
    load_instances
    save_breadcrumb(instance_path(@instance), @instance.name)
    @events = @instance.events.paginate(:page => params[:page] || 1)
    @view = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    @details_tab = 'properties' unless ['properties', 'history',
                                        'parameters', 'permissions'].include?(@details_tab)
    @tabs = [
      {:name => _("Properties"), :view => @view, :id => 'properties'},
      {:name => _("Config Parameters"), :view => 'parameters', :id => 'parameters'},
      {:name => _("History"), :view => 'history', :id => 'history'}
    ]
    @details_tab = @tabs.find {|t| t[:view] == @view}
    respond_to do |format|
      format.html { render :action => 'show'}
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab[:view] and return
      end
      format.json { render :json => @instance }
      format.xml
    end
  end

  def edit
    require_privilege(Privilege::MODIFY, @instance)
    respond_to do |format|
      format.html
      format.js { render :partial => 'edit', :id => @instance.id }
      format.json { render :json => @instance }
    end
  end

  def update
    # TODO - This USER_MUTABLE_ATTRS business is because what a user and app components can do
    # will be greatly different. (e.g., a user shouldn't be able to change an instance's pool,
    # since it won't do what they expect). As we build this out, this logic will become more complex.
    attrs = {}
    params[:instance].each_pair{|k,v| attrs[k] = v if Instance::USER_MUTABLE_ATTRS.include?(k)}
    respond_to do |format|
      if check_privilege(Privilege::MODIFY, @instance) and @instance.update_attributes(attrs)
        flash[:success] = t('instances.flash.success.updated', :list => @instance.name)
        format.html { redirect_to @instance }
        format.js { render :partial => 'properties' }
        format.json { render :json => @instance }
      else
        flash[:error] = t('instances.flash.error.not_updated', :list => @instance.name)
        format.html { render :action => :edit }
        format.js { render :partial => 'edit' }
        format.json { render :json => @instance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    destroyed = []
    failed = []
    Instance.find(ids_list).each do |instance|
      if check_privilege(Privilege::MODIFY, instance) && instance.destroyable?
        instance.destroy
        destroyed << instance.name
      else
        failed << instance.name
      end
    end
    flash[:success] = t('instances.flash.success.deleted', :list => destroyed.to_sentence, :count => destroyed.size) if destroyed.present?
    flash[:error] = t('instances.flash.error.not_deleted', :list => failed.to_sentence, :count => failed.size) if failed.present?
    respond_to do |format|
      # FIXME: _list does not show flash messages, but I'm not sure that showing _list is proper anyway
      format.html { render :action => :show }
      format.js do
        set_view_vars
        load_instances
        render :partial => 'list'
      end
      format.json { render :json => {:success => destroyed, :errors => failed} }
    end
  end

  def key
    respond_to do |format|
      if @instance.instance_key.nil?
        flash[:warning] = _("SSH Key not found for this Instance.")
        format.html { redirect_to instance_path(@instance) }
        format.js { render :partial => 'properties' }
        format.json { render :json => flash[:warning], :status => :not_found }
      else
        format.html { send_data @instance.instance_key.pem,
                                :filename => "#{@instance.instance_key.name}.pem",
                                :type => "text/plain" }
        format.js do
          send_data @instance.instance_key.pem,
                                :filename => "#{@instance.instance_key.name}.pem",
                                :type => "text/plain"
        end
        format.json { render :json => {:key => @instance.instance_key.pem,
                                      :filename => "#{@instance.instance_key.name}.pem",
                                      :type => "text/plain" } }
      end
    end
  end

  def multi_stop
    notices = []
    errors = []

    @instances_to_stop.each do |instance|
      begin
        require_privilege(Privilege::USE,instance)

        if @inaccessible_instances.include?(instance)
          instance.forced_stop(current_user)
          notices << "#{instance.name}: #{_("state changed to stopped.")}"
        else
          instance.stop(current_user)
          notices << "#{instance.name}: #{_("stop action was successfully queued.")}"
        end
      rescue Exception => ex
        errors << "#{instance.name}: " + ex.message
        log_backtrace(ex)
      end
    end
    errors = _("You must select one or more Instances to stop.") if errors.blank? && notices.blank?
    flash[:notice] = notices unless notices.blank?
    flash[:error] = errors unless errors.blank?
    respond_to do |format|
      format.html { redirect_to params[:backlink] || pools_path(:view => 'filter', :details_tab => 'instances') }
      format.json { render :json => {:success => notices, :errors => errors} }
    end
  end

  def export_events
    send_data(Instance.csv_export(load_instances),
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => "export.csv")
  end

  def stop
    if @inaccessible_instances.include?(@instance)
      do_operation(:forced_stop)
    else
      do_operation(:stop)
    end
  end

  def reboot
    do_operation(:reboot)
  end

  def multi_reboot
    notices = []
    errors = []
    Instance.find(params[:instance_selected] || []).each do |instance|
      begin
        require_privilege(Privilege::USE,instance)
        instance.reboot(current_user)
        notices << "#{instance.name}: " +  _("%s: reboot action was successfully queued.") % instance.name
      rescue Exception => ex
        errors << "#{instance.name}: " + ex.message
        log_backtrace(ex)
      end
    end
    # If nothing is selected, display an error message:
    errors = _("You must select one or more Instances to reboot.") if errors.blank? && notices.blank?
    flash[:notice] = notices unless notices.blank?
    flash[:error] = errors unless errors.blank?
    respond_to do |format|
      format.html { redirect_to params[:backlink] || pools_path(:view => 'filter', :details_tab => 'instances') }
      format.json { render :json => {:success => notices, :errors => errors} }
    end
  end

  def filter
    redirect_to_original({"instances_preset_filter" => params[:instances_preset_filter], "instances_search" => params[:instances_search]})
  end

  private

  def load_instance
    @instance = Instance.find(Array(params[:id]).first)
    require_privilege(Privilege::USE,@instance)
  end

  def init_new_instance_attrs
    @pools = Pool.list_for_user(current_session, current_user,
                                Privilege::CREATE, Instance).
      where(:enabled => true)
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {
        :provider_id => nil
       #FIXME arch?
      }
    )
  end

  def set_view_vars
    @header = [
      {:name => _("VM NAME"), :sort_attr => 'name'},
      {:name => _("STATUS"), :sortable => false},
      {:name => _("PUBLIC ADDRESS"), :sort_attr => 'public_addresses'},
      {:name => _("PROVIDER"), :sortable => false},
      {:name => _("CREATED BY"), :sort_attr => 'users.last_name'},
    ]

    @pools = Pool.list_for_user(current_session, current_user,
                                Privilege::CREATE, Instance)
  end

  def load_instances
    if params[:deployment_id].blank?
      @instances = paginate_collection(
        Instance.includes(:owner).
          apply_filters(:preset_filter_id => params[:instances_preset_filter],
                        :search_filter => params[:instances_search]).
          list_for_user(current_session, current_user, Privilege::VIEW).
          list(sort_column(Instance), sort_direction).
          where("instances.pool_id" => @pools),
        params[:page], PER_PAGE)
    else
      @instances = paginate_collection(
        Instance.includes(:owner).
          apply_filters(:preset_filter_id => params[:instances_preset_filter],
                        :search_filter => params[:instances_search]).
          list(sort_column(Instance), sort_direction).
          list_for_user(current_session, current_user, Privilege::VIEW).
          where("instances.pool_id" => @pools,
                "instances.deployment_id" => params[:deployment_id]),
        params[:page], PER_PAGE)
    end
  end

  def check_inaccessible_instances
    # @instance is set only on stop action
    @instances_to_stop = @instance ? Array(@instance) : Instance.find(Array(params[:instance_selected]))
    @instances_to_stop.reject! { |inst| !check_privilege(Privilege::USE, inst) }
    @inaccessible_instances = Instance.stoppable_inaccessible_instances(@instances_to_stop)
    if params[:terminate].blank? and @inaccessible_instances.any?
      respond_to do |format|
        format.html { render :action => :confirm_terminate }
        format.json { render :json => {:inaccessbile_instances => @inaccessible_instances}, :status => :unprocessable_entity }
      end
      return false
    end
    return true
  end

  def do_operation(operation)
    begin
      @instance.send(operation, current_user)
      flash[:notice] = t("instances.flash.notice.#{operation}", :name => @instance.name)
    rescue Exception => err
      flash[:error] = t("instances.flash.error.#{operation}", :name => @instance.name, :err => err)
    end
    respond_to do |format|
      format.html { redirect_to deployment_path(@instance.deployment, :details_tab => 'instances') }
    end
  end
end
