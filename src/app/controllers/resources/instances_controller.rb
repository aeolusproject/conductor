class Resources::InstancesController < ApplicationController
  before_filter :require_user

  def new
  end

  def edit
  end

  def start
  end

  def stop
  end

  def index
    @header = [
      {:name => 'VM NAME', :sort_attr => 'name'},
      {:name => 'STATUS', :sortable => false},
      {:name => 'TEMPLATE', :sort_attr => 'templates.name'},
      {:name => 'PUBLIC ADDRESS', :sort_attr => 'public_addresses'},
      {:name => 'PROVIDER', :sortable => false},
      {:name => 'CREATED BY', :sort_attr => 'users.last_name'},
      {:name => '', :sortable => false},
    ]

    pools = Pool.list_for_user(@current_user, Privilege::INSTANCE_MODIFY)
    @instances = Instance.all(
      :include => [:template, :owner],
      :conditions => {:pool_id => pools},
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end
end
