require 'util/taskomatic'

class InstanceController < ApplicationController
  def index
  end

  # Right now this is essentially a duplicate of PortalPoolController#show,
    # but really it should be a single instance should we decide to have a page
    # for that.  Redirect on create was all that brought you here anyway, so
    # should be unused for the moment.
  def show
    @instances = Instance.find(:all, :conditions => {:portal_pool_id => params[:id]})
    @pool = PortalPool.find(params[:id])
    @provider = @pool.cloud_account.provider
  end

  def new
    @instance = Instance.new({:portal_pool_id => params[:id]})
    _new(params[:provider])
  end

  def create
    @instance = Instance.new(params[:instance])
    @instance.state = Instance::STATE_NEW
    #FIXME: This should probably be in a transaction
    if @instance.save

      @task = InstanceTask.new({:user        => @instance.portal_pool.cloud_account.username,
                                :task_target => @instance,
                                :action      => InstanceTask::ACTION_CREATE})
      if @task.save
        task_impl = Taskomatic.new(@task)
        task_impl.instance_create
        flash[:notice] = "Instance added."
        redirect_to :controller => "portal_pool", :action => 'show', :id => @instance.portal_pool_id
      else
        _new(params[:provider_id])
        render :action => 'new'
      end
    else
      _new(params[:provider_id])
      render :action => 'new'
    end
  end

  def instance_action
    action = params[:instance_action]
    action_args = params[:action_data]
    @instance = Instance.find(params[:id])
    unless @instance.valid_action?(action)
      raise ActionError.new("#{action} is an invalid action.")
    end
    #permissons check here
    @task = @instance.queue_action(get_login_user, action, action_args)
    unless @task
      raise ActionError.new("#{action} cannot be performed on this instance.")
    end

    task_impl = Taskomatic.new(@task)
    task_impl.send "instance_#{action}"

    alert = "#{@instance.name}: #{action} was successfully queued."
    flash[:notice] = alert
    redirect_to :controller => "portal_pool", :action => 'show', :id => @instance.portal_pool_id
  end

  def delete
  end

  private

  def _new(provider)
    @flavors = Flavor.find(:all, :conditions => {:provider_id => provider})
    @images = Image.find(:all, :conditions => {:provider_id => provider})
    @realms = Realm.find(:all, :conditions => {:provider_id => provider})
    @provider_id = provider
  end

end
