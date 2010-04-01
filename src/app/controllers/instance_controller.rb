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

require 'util/taskomatic'

class InstanceController < ApplicationController
  before_filter :require_user

  def index
  end

  # Right now this is essentially a duplicate of PoolController#show,
    # but really it should be a single instance should we decide to have a page
    # for that.  Redirect on create was all that brought you here anyway, so
    # should be unused for the moment.
  def show
    @instances = Instance.find(:all, :conditions => {:pool_id => params[:id]})
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::INSTANCE_VIEW,@pool)
  end

  def new
    @instance = Instance.new({:pool_id => params[:id]})
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::INSTANCE_MODIFY,@pool)
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
        task_impl = Taskomatic.new(@task,logger)
        task_impl.instance_create
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

    task_impl = Taskomatic.new(@task,logger)
    task_impl.send "instance_#{action}"

    alert = "#{@instance.name}: #{action} was successfully queued."
    flash[:notice] = alert
    redirect_to :controller => "pool", :action => 'show', :id => @instance.pool_id
  end

  def delete
  end

end
