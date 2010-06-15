class TemplatesController < ApplicationController
  layout :layout
  before_filter :require_user

  def layout
    return "aggregator" unless ajax?
  end

  def ajax?
    return params[:ajax] == "true"
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
      update_xml
      @repositories = RepositoryManager.new.repositories
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
      @image_descriptor = params[:id] ? ImageDescriptor.find(params[:id]) : ImageDescriptor.new
      @image_descriptor.update_xml_attributes!(params[:xml] || {})
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
      @all_targets = ImageDescriptorTarget.available_targets
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

  def selected_packages
    data = ImageDescriptor.find(params[:id]).xml.packages
  end

  def repository_packages
    @packages = []
    rmanager = RepositoryManager.new
    rmanager.repositories.keys.each do |repid|
      next if params[:repository] and params[:repository] != 'all' and repid != params[:repository]
      rep = rmanager.get_repository(repid)
      @packages += rep.get_packages
    end
  end

  def repository_packages_by_group
    @packages = {}
    rmanager = RepositoryManager.new
    rmanager.repositories.keys.each do |repid|
      next if params[:repository] and params[:repository] != 'all' and repid != params[:repository]
      rep = rmanager.get_repository(repid)
      rep.get_packages_by_group.each do |group, pkgs|
        @packages[group] ||= []
        @packages[group] += pkgs
      end
    end
  end

  private

  def update_xml
    @image_descriptor = params[:id] ? ImageDescriptor.find(params[:id]) : ImageDescriptor.new
    @image_descriptor.update_xml_attributes!(params[:xml] || {})
  end
end
