#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'util/condormatic'

class InstanceController < ApplicationController
  before_filter :require_user
  layout :layout

  def layout
    return "aggregator" unless request.xhr?
  end

  def index
    require_privilege(Privilege::INSTANCE_VIEW)

    # go to condor and sync the database to the real instance states
    condormatic_instances_sync_states

    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order = params[:order] || 'name'
    @instances = Instance.search_filter(params[:search], Instance::SEARCHABLE_COLUMNS).paginate(
      :page => params[:page] || 1,
      :order => @order + ' ' + @order_dir
    )

    if request.xhr? and params[:partial]
      render :partial => 'instances'
      return
    end
  end

  def select_image
    if params[:select]
      redirect_to :action => 'new', 'instance[image_id]' => (params[:ids] || []).first
    end

    require_privilege(Privilege::IMAGE_VIEW)
    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order = params[:order] || 'name'
    @images = Image.search_filter(params[:search], Image::SEARCHABLE_COLUMNS).paginate(
      :page => params[:page] || 1,
      :order => @order + ' ' + @order_dir,
      :conditions => {:provider_id => nil}
    )
    @single_select = true

    if request.xhr? and params[:partial]
      render :partial => 'image/images'
      return
    end
  end

  ## Right now this is essentially a duplicate of PoolController#show,
  #  # but really it should be a single instance should we decide to have a page
  #  # for that.  Redirect on create was all that brought you here anyway, so
  #  # should be unused for the moment.
  #def show
  #  require_privilege(Privilege::INSTANCE_VIEW,@pool)
  #  @pool = Pool.find(params[:id])
  #  @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
  #  @order = params[:order] || 'name'
  #  @instances = Instance.search_filter(params[:search], Instance::SEARCHABLE_COLUMNS).paginate(
  #    :page => params[:page] || 1,
  #    :order => @order + ' ' + @order_dir,
  #    :conditions => {:pool_id => @pool.id}
  #  )
  #  if request.xhr? and params[:partial]
  #    render :partial => 'instances'
  #    return
  #  end
  #end

  def new
    @instance = Instance.new(params[:instance])
    require_privilege(Privilege::INSTANCE_MODIFY, @instance.pool) if @instance.pool
    @pools = Pool.list_for_user(@current_user, Privilege::INSTANCE_MODIFY)
    # FIXME: what error msg to show if no pool is selected and the user has
    # permission on none?
    @instance.pool = @pools[0] if (@instance.pool.nil? and (@pools.size == 1))
  end

  def create
    @instance = Instance.new(params[:instance])
    @instance.state = Instance::STATE_NEW
    require_privilege(Privilege::INSTANCE_MODIFY,
                      Pool.find(@instance.pool_id))
    #FIXME: This should probably be in a transaction
    if @instance.save

      @task = InstanceTask.new({:user        => current_user,
                                :task_target => @instance,
                                :action      => InstanceTask::ACTION_CREATE})
      if @task.save
        condormatic_instance_create(@task)
        flash[:notice] = "Instance added."
        redirect_to :controller => "pool", :action => 'show', :id => @instance.pool_id
      else
        @pool = @instance.pool
        render :action => 'new'
      end
    else
      @pool = Pool.find(@instance.pool_id)
      render :action => 'new'
    end
  end

  def instance_action
    action = params[:instance_action]
    action_args = params[:action_data]
    @instance = Instance.find(params[:id])
    require_privilege(Privilege::INSTANCE_CONTROL,@instance.pool)
    unless @instance.valid_action?(action)
      raise ActionError.new("#{action} is an invalid action.")
    end
    #permissons check here
    @task = @instance.queue_action(@current_user, action, action_args)
    unless @task
      raise ActionError.new("#{action} cannot be performed on this instance.")
    end

    case action
      when 'stop'
        condormatic_instance_stop(@task)
      when 'destroy'
        condormatic_instance_destroy(@task)
      when 'start'
        condormatic_instance_create(@task)
      else
        raise ActionError.new("Sorry, action '#{action}' is currently not supported by condor backend.")
    end

    alert = "#{@instance.name}: #{action} was successfully queued."
    flash[:notice] = alert
    redirect_to :controller => "pool", :action => 'show', :id => @instance.pool_id
  end

  def delete
  end

end
