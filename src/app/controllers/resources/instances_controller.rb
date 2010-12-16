class Resources::InstancesController < ApplicationController
  before_filter :require_user

  def new
    @instance = Instance.new(params[:instance])
    #require_privilege(Privilege::INSTANCE_MODIFY, @instance.pool) if @instance.pool

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
      :include => {:images => :replicated_images},
      :conditions => "replicated_images.uploaded = 't'"
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
      require_privilege(Privilege::INSTANCE_MODIFY,
                        Pool.find(@instance.pool_id))
      free_quota = Quota.can_start_instance?(@instance, nil)
      @instance.transaction do
        @instance.save!
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
    @instance = Instance.find((params[:id] || []).first)
    require_privilege(Privilege::INSTANCE_CONTROL,@instance.pool)
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

  def index
    @header = [
      {:name => 'VM NAME', :sort_attr => 'name'},
      {:name => 'STATUS', :sortable => false},
      {:name => 'TEMPLATE', :sort_attr => 'templates.name'},
      {:name => 'PUBLIC ADDRESS', :sort_attr => 'public_addresses'},
      {:name => 'PROVIDER', :sortable => false},
      {:name => 'CREATED BY', :sort_attr => 'users.last_name'},
    ]

    pools = Pool.list_for_user(@current_user, Privilege::INSTANCE_MODIFY)
    @instances = Instance.all(
      :include => [:template, :owner],
      :conditions => {:pool_id => pools},
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end

  def key
    @instance = Instance.find((params[:id] || []).first)
    require_privilege(Privilege::INSTANCE_CONTROL,@instance.pool)
    unless @instance.instance_key.nil?
      send_data @instance.instance_key.pem,
                :filename => "#{@instance.instance_key.name}.pem",
                :type => "text/plain"
      return
    end
    flash[:warning] = "SSH Key not found for this Instance."
    redirect_to resources_instance_path(@instance)
  end

  private

  def init_new_instance_attrs
    @pools = Pool.list_for_user(@current_user, Privilege::INSTANCE_MODIFY)
    @realms = Realm.find(:all, :conditions => { :provider_id => nil })
    @hardware_profiles = HardwareProfile.all(
      :include => :architecture,
      :conditions => {
        :provider_id => nil,
        'hardware_profile_properties.value' => @instance.template.architecture
      }
    )
  end
end
