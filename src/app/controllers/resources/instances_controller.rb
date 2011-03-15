class Resources::InstancesController < ApplicationController
  before_filter :require_user, :except => [:can_start, :can_create]
  before_filter :load_instance, :only => [:show, :remove_failed, :key, :stop]
  before_filter :set_view_vars, :only => [:show, :index]

  def index
    @params = params
    @search_term = params[:q]
    if @search_term.blank?
      load_instances
      return
    end

    search = Instance.search do
      keywords(params[:q])
    end
    @instances = search.results
  end

  def new
    @instance = Instance.new(params[:instance])
    require_privilege(Privilege::CREATE, Instance, @instance.pool) if @instance.pool

    unless @instance.template
      redirect_to select_template_resources_instances_path
      return
    end

    init_new_instance_attrs
  end

  def select_template
    # FIXME: we need to list only templates for particular user,
    # => TODO: add TEMPLATE_* permissions
    @templates = Template.paginate(
      :page => params[:page] || 1,
      :include => {:images => :provider_images},
      :conditions => "provider_images.status = '#{ProviderImage::STATE_COMPLETE}'"
    )
  end

  def create
    if params[:cancel]
      redirect_to select_template_resources_instances_path
      return
    end

    @instance = Instance.new(params[:instance])
    @instance.state = Instance::STATE_NEW
    @instance.owner = current_user

    begin
      require_privilege(Privilege::CREATE, Instance,
                        Pool.find(@instance.pool_id))
      free_quota = Quota.can_start_instance?(@instance, nil)
      @instance.transaction do
        @instance.save!
        # set owner permissions:
        @instance.assign_owner_roles(current_user)
        @task = InstanceTask.create!({:user        => current_user,
                                      :task_target => @instance,
                                      :action      => InstanceTask::ACTION_CREATE})
        condormatic_instance_create(@task)
      end
    rescue
      init_new_instance_attrs
      flash[:warning] = "Failed to launch instance: #{$!}"
      render :new
    else
      if free_quota
        flash[:notice] = "Instance added."
      else
        flash[:warning] = "Quota Exceeded: Instance will not start until you have free quota"
      end
      redirect_to resources_instances_path
    end
  end

  def edit
  end

  def show
    load_instances
    @url_params = params.clone
    @tab_captions = ['Properties', 'History', 'Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
    end
  end

  def key
    unless @instance.instance_key.nil?
      send_data @instance.instance_key.pem,
                :filename => "#{@instance.instance_key.name}.pem",
                :type => "text/plain"
      return
    end
    flash[:warning] = "SSH Key not found for this Instance."
    redirect_to resources_instance_path(@instance)
  end

  def stop
    unless @instance.valid_action?('stop')
      raise ActionError.new("stop is an invalid action.")
    end

    # not sure if task is used as everything goes through condor
    #permissons check here
    @task = @instance.queue_action(@current_user, 'stop')
    unless @task
      raise ActionError.new("stop cannot be performed on this instance.")
    end
    condormatic_instance_stop(@task)
    flash[:notice] = "#{@instance.name}: stop action was successfully queued."
    redirect_to resources_instances_path
  end

  def remove_failed
    raise ActionError.new("remove failed cannot be performed on this instance.") unless
      @instance.state == Instance::STATE_ERROR
    condormatic_instance_reset_error(@instance)
    flash[:notice] = "#{@instance.name}: remove failed action was successfully queued."
    redirect_to resources_instances_path
  end

  def can_create
    begin
      provider_account = ProviderAccount.find(params[:provider_account_id])
      @instance = Instance.find(params[:instance_id])
      @action_request = "can_create"
      @value = Quota.can_create_instance?(@instance, provider_account)
      render :partial => 'can_perform_state_change.xml'
    rescue ActiveRecord::RecordNotFound
      head :not_found
    rescue Exception
      head :internal_server_error
    end
  end

  def can_start
    begin
      provider_account = ProviderAccount.find(params[:provider_account_id])
      @instance = Instance.find(params[:instance_id])
      @action_request = "can_start"
      @value = Quota.can_start_instance?(@instance, provider_account)
      render :partial => 'can_perform_state_change.xml'
    rescue ActiveRecord::RecordNotFound => e
      puts e.inspect
      head :not_found
    rescue Exception => e
      puts e.inspect
      head :internal_server_error
    end
  end

  private

  def load_instance
    @instance = Instance.find(params[:id].to_a.first)
    require_privilege(Privilege::USE,@instance)
  end

  def init_new_instance_attrs
    @pools = Pool.list_for_user(@current_user, Privilege::MODIFY, :target_type => Instance)
    @realms = FrontendRealm.all
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {
        :provider_id => nil,
        'hardware_profile_properties.value' => @instance.template.architecture
      }
    )
  end

  def set_view_vars
    @header = [
      {:name => 'VM NAME', :sort_attr => 'name'},
      {:name => 'STATUS', :sortable => false},
      {:name => 'TEMPLATE', :sort_attr => 'templates.name'},
      {:name => 'PUBLIC ADDRESS', :sort_attr => 'public_addresses'},
      {:name => 'PROVIDER', :sortable => false},
      {:name => 'CREATED BY', :sort_attr => 'users.last_name'},
    ]

    @pools = Pool.list_for_user(@current_user, Privilege::MODIFY, :target_type => Instance)
  end

  def load_instances
    @instances = Instance.all(:include => [:template, :owner],
                              :conditions => {:pool_id => @pools},
                              :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end
end
