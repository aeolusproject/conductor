class ImageDescriptorController < ApplicationController
  layout :layout
  before_filter :require_user

  TABS = %w(basics services software summary)

  def layout
    return "aggregator" unless ajax?
  end

  def ajax?
    return params[:ajax] == "true"
  end

  def new
    # FIXME: check permission, something like IMAGE_CREATE
    if params[:commit] == 'Cancel' or params[:commit] == 'Done'
      redirect_to :controller => "dashboard", :action => 'index'
      return
    elsif params[:commit] == 'Build'
      @tab = 'summary'
      if params[:targets]
        params[:targets].each do |target|
          ImageDescriptorTarget.new_if_not_exists(:name => target, :image_descriptor_id => params[:image_descriptor][:id], :status => ImageDescriptorTarget::STATE_QUEUED)
        end
      end
    end

    unless @tab
      @old_tab = TABS.index(params[:tab]) || nil
      next_idx = @old_tab ? @old_tab + (params[:commit] == 'Back' ? -1 : 1) : 0
      @tab = (next_idx < 0 || next_idx > TABS.size) ? TABS[0] : TABS[next_idx]
    end

    @image_descriptor = params[:image_descriptor] && params[:image_descriptor][:id] ? ImageDescriptor.find(params[:image_descriptor][:id]) : ImageDescriptor.new
    @image_descriptor.update_xml_attributes!(params[:xml] || {})

    if @tab == 'summary'
      @image_descriptor.complete = true
      @image_descriptor.save!
    end

    if @tab == 'software'
      @repositories = RepositoryManager.new.repositories
    elsif @tab == 'summary'
      @all_targets = ImageDescriptorTarget.available_targets
    end
  end

  def create
    if params[:commit] == 'Cancel'
      redirect_to :controller => "image", :action => 'show'
      return
    end
    redirect_to :action => 'images', :tab => 'show'
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
end
