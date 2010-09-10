require 'util/repository_manager'

class TemplatesController < ApplicationController
  layout :layout
  before_filter :require_user, :check_permission, :check_for_cancel

  def layout
    request.xhr? ? false : 'aggregator'
  end

  def index
    @repository_manager = RepositoryManager.new
    @pools = Pool.list_for_user(@current_user, Privilege::POOL_VIEW)
  end

  def new
    update_xml
    if params[:next]
      redirect_to :action => 'services', :id => @image_descriptor
    end
  end

  def packages
    repository_manager = RepositoryManager.new
    @packages = repository_manager.get_packages
  end

  def builds
    #This will be the list of builds associated with template specified by {id}
  end

  def services
    update_xml
    if params[:back]
      redirect_to :action => 'new', :id => @image_descriptor
    elsif params[:next]
      redirect_to :action => 'software', :id => @image_descriptor
    end
  end

  def software
    @repository_manager = RepositoryManager.new
    @image_descriptor = params[:id] ? ImageDescriptor.find(params[:id]) : ImageDescriptor.new
    @groups = @repository_manager.all_groups(params[:repository])
    if params[:tab].to_s == 'packages'
      @selected_tab = 'packages'
      @packages = @repository_manager.all_packages(params[:repository])
    else
      @selected_tab = 'groups'
    end

    if request.xhr?
      render :partial => @selected_tab
      return
    end

    @image_descriptor.update_xml_attributes!(params[:xml] || {})

    if params[:back]
      redirect_to :action => 'services', :id => @image_descriptor
    elsif params[:next]
      redirect_to :action => 'summary', :id => @image_descriptor
    end
  end

  def summary
    update_xml
    @all_targets = ImageDescriptorTarget.available_targets
    if params[:build]
      if params[:targets]
        params[:targets].each do |target|
          ImageDescriptorTarget.new_if_not_exists(:name => target, :image_descriptor_id => params[:id], :status => ImageDescriptorTarget::STATE_QUEUED)
        end
      end
    else
      if params[:back]
        redirect_to :action => 'software', :id => @image_descriptor
      elsif params[:done]
        @image_descriptor.complete = true
        @image_descriptor.save!
        redirect_to :controller => 'dashboard', :action => 'index'
      end
    end
  end

  def targets
    @image_descriptor = ImageDescriptor.find(params[:id])
    @all_targets = ImageDescriptorTarget.available_targets
  end

  def select_group
    update_group_or_package(:add_group, params[:group])
  end

  def remove_group
    update_group_or_package(:remove_group, params[:group])
  end

  def select_package
    update_group_or_package(:add_package, params[:package], params[:group])
  end

  private

  def check_for_cancel
    if params[:cancel]
      redirect_to :controller => "dashboard", :action => 'index'
      return false
    end
    return true
  end

  def check_permission
    require_privilege(Privilege::IMAGE_MODIFY)
  end

  def update_group_or_package(method, *args)
    @image_descriptor = params[:id] ? ImageDescriptor.find(params[:id]) : ImageDescriptor.new
    @image_descriptor.xml.send(method, *args)
    @image_descriptor.save_xml!
    if request.xhr?
      render :partial => 'selected_packages'
    else
      redirect_to :action => 'software', :id => @image_descriptor
    end
  end

  def update_xml
    @image_descriptor = params[:id] ? ImageDescriptor.find(params[:id]) : ImageDescriptor.new
    @image_descriptor.update_xml_attributes!(params[:xml] || {})
  end

  def check_permission
    require_privilege(Privilege::IMAGE_MODIFY)
  end
end
