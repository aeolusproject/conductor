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

class InstancesController < ApplicationController
  before_filter :require_user
  before_filter :load_instance, :only => [:show, :key, :edit, :update]
  before_filter :set_view_vars, :only => [:show, :index, :export_events]

  def index
    @params = params
    save_breadcrumb(instances_path(:viewstate => viewstate_id))
    load_instances

    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.json { render :json => @instances }

    end
  end

  def new
  end

  def create
  end

  def show
    load_instances
    @tab_captions = [t('instances.tab_captions.properties'), t('instances.tab_captions.history'), t('instances.tab_captions.permissions')]
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    save_breadcrumb(instance_path(@instance), @instance.name)
    respond_to do |format|
      format.html { render :action => 'show'}
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.json { render :json => @instance }
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
        flash[:success] = t('instances.flash.success.updated', :count => 1, :list => @instance.name)
        format.html { redirect_to @instance }
        format.js { render :partial => 'properties' }
        format.json { render :json => @instance }
      else
        flash[:error] = t('instances.flash.error.not_updated', :count =>1, :list => @instance.name)
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
        flash[:warning] = t "instances.flash.warning.ssh_key_not_found"
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
    notices = ""
    errors = ""
    Instance.find(params[:instance_selected] || []).each do |instance|
      begin
        require_privilege(Privilege::USE,instance)
        unless instance.valid_action?('stop')
          raise ActionError.new(t('instances.errors.stop_invalid'))
        end

        #permissons check here
        @task = instance.queue_action(current_user, 'stop')
        unless @task
          raise ActionError.new(t('instances.errors.stop_not_be_performed'))
        end
        Taskomatic.stop_instance(@task)
        notices << "#{instance.name}: #{t('instances.flash.notice.stop')}"
      rescue Exception => err
        errors << "#{instance.name}: " + err
      end
    end
    # If nothing is selected, display an error message:
    errors = t('instances.none_selected') if errors.blank? && notices.blank?
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

  private

  def load_instance
    @instance = Instance.find(params[:id].to_a.first)
    require_privilege(Privilege::USE,@instance)
  end

  def init_new_instance_attrs
    @pools = Pool.list_for_user(current_user, Privilege::CREATE, Instance).where(:enabled => true)
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
      {:name => t('instances.headers.vm_name'), :sort_attr => 'name'},
      {:name => t('instances.headers.status'), :sortable => false},
      {:name => t('instances.headers.public_address'), :sort_attr => 'public_addresses'},
      {:name => t('instances.headers.provider'), :sortable => false},
      {:name => t('instances.headers.created_by'), :sort_attr => 'users.last_name'},
    ]

    @pools = Pool.list_for_user(current_user, Privilege::CREATE, Instance)
  end

  def load_instances
    conditions = { :pool_id => @pools }
    conditions[:deployment_id] = params[:deployment_id] unless params[:deployment_id].blank?
    @instances = Instance.all(:include => [:owner],
                              :conditions => conditions,
                              :order => (sort_column(Instance) +' '+ sort_direction)
    )
  end
end
