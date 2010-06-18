require 'util/repository_manager'

class TemplatesController < ApplicationController
  layout :layout
  before_filter :require_user, :check_permission

  def layout
    request.xhr? ? false : 'aggregator'
  end

  def new
    if params[:cancel]
      redirect_to :controller => "dashboard", :action => 'index'
    else
      update_xml
    end
  end

  def services
    if params[:cancel]
      redirect_to :controller => "dashboard", :action => 'index'
    else
      update_xml
    end
  end

  def software
    if params[:cancel]
      redirect_to :controller => "dashboard", :action => 'index'
    else
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
        redirect_to :action => 'new', :id => params[:id]
        return
      end
    end
  end

  def summary
    if params[:cancel]
      redirect_to :controller => "dashboard", :action => 'index'
    else
      update_xml
      @image_descriptor.complete = true
      @image_descriptor.save!
      @all_targets = ImageDescriptorTarget.available_targets
      if params[:back]
        redirect_to :action => 'services', :id => params[:id]
        return
      end
    end
  end

  def build
    if params[:cancel] or params[:done]
      redirect_to :controller => "dashboard", :action => 'index'
    elsif params[:back]
      redirect_to :action => 'software', :id => params[:id]
    else
      if params[:targets]
        params[:targets].each do |target|
          ImageDescriptorTarget.new_if_not_exists(:name => target, :image_descriptor_id => params[:id], :status => ImageDescriptorTarget::STATE_QUEUED)
        end
      end
      redirect_to :action => 'summary', :id => params[:id]
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

  def check_permission
    #require_privilege(Privilege::IMAGE_MODIFY)
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
