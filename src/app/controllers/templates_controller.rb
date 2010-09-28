require 'util/repository_manager'

class TemplatesController < ApplicationController
  before_filter :require_user
  before_filter :check_permission, :except => [:index, :builds]

  def index
    # TODO: add template permission check
    require_privilege(Privilege::IMAGE_VIEW)
    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order_field = params[:order_field] || 'name'
    @templates = Template.find(
      :all,
      :include => :images,
      :order => @order_field + ' ' + @order_dir
    )
  end

  def action
    if params[:new_template]
      redirect_to :action => 'new'
    elsif params[:assembly]
      redirect_to :action => 'assembly'
    elsif params[:deployment_definition]
      redirect_to :action => 'deployment_definition'
    elsif params[:delete]
      redirect_to :action => 'delete', :ids => params[:ids].to_a
    elsif params[:edit]
      redirect_to :action => 'new', :id => get_selected_id
    elsif params[:build]
      redirect_to :action => 'build_form', 'image[template_id]' => get_selected_id
    else
      raise "Unknown action"
    end
  end

  def new
    # can't use @template variable - is used by compass (or something other)
    @tpl = Template.find_or_create(params[:id])
    @repository_manager = RepositoryManager.new
    @groups = @repository_manager.all_groups(params[:repository])
  end

  #def select_package
  #  update_group_or_package(:add_package, params[:package], params[:group])
  #  render :action => 'new'
  #end

  #def remove_package
  #  update_group_or_package(:remove_package, params[:package], params[:group])
  #  render :action => 'new'
  #end

  def create
    @tpl = (params[:tpl] && !params[:tpl][:id].to_s.empty?) ? Template.find(params[:tpl][:id]) : Template.new(params[:tpl])
    # this is crazy, but we have most attrs in xml and also in model,
    # synchronize it at first to xml
    @tpl.update_xml_attributes!(params[:tpl])

    # if add/remove pkg/group, we only update xml and render 'new' template
    # again
    if update_selection
      render :action => 'new'
      return
    end

    if @tpl.save
      flash[:notice] = "Template saved."
      @tpl.set_complete
      redirect_to :action => 'index'
    else
      @repository_manager = RepositoryManager.new
      @groups = @repository_manager.all_groups(params[:repository])
      render :action => 'new'
    end
  end

  def build_form
    raise "select template to build" unless params[:image] and params[:image][:template_id]
    @image = Image.new(params[:image])
    @all_targets = Image.available_targets
  end

  def build
    if params[:cancel]
      redirect_to :action => 'index'
      return
    end

    #FIXME: The following functionality needs to come out of the controller
    @image = Image.new(params[:image])
    @image.template.upload_template unless @image.template.uploaded
    # FIXME: this will need to re-render build with error messages,
    # just fails right now if anything is wrong (like no target selected).
    params[:targets].each do |target|
      i = Image.new_if_not_exists(
        :name => "#{@image.template.xml.name}/#{target}",
        :target => target,
        :template_id => @image.template_id,
        :status => Image::STATE_QUEUED
      )
      # FIXME: This will need to be enhanced to handle multiple
      # providers of same type, only one is supported right now
      if i
        image = Image.find_by_template_id(params[:image][:template_id],
                                :conditions => {:target => target})
        ReplicatedImage.create!(
          :image_id => image.id,
          :provider_id => Provider.find_by_cloud_type(target)
        )
      end
    end
    redirect_to :action => 'builds'
  end

  def builds
    @running_images = Image.all(:include => :template, :conditions => ['status IN (?)', Image::ACTIVE_STATES])
    @completed_images = Image.all(:include => :template, :conditions => {:status => Image::STATE_COMPLETE})
    require_privilege(Privilege::IMAGE_VIEW)
  end

  def delete
    Template.destroy(params[:ids].to_a)
    redirect_to :action => 'index'
  end

  def assembly
  end

  def deployment_definition
    @all_targets = Image.available_targets
  end

  private

  def update_selection
    # TODO: don't know better way how to select package and also save other form data than
    # passing pkg/group as part of submit button name
    params.keys.each do |param|
      if param =~ /^select_package_(.*)$/
        update_group_or_package(:add_package, $1, nil)
        return true
      elsif param =~ /^remove_package_(.*)$/
        update_group_or_package(:remove_package, $1, nil)
        return true
      elsif param =~ /^select_group_(.*)$/
        update_group_or_package(:add_group, $1)
        return true
      end
    end
    return false
  end

  def update_group_or_package(method, *args)
    @repository_manager = RepositoryManager.new
    @groups = @repository_manager.all_groups(params[:repository])
    @tpl.xml.send(method, *args)
    # we save template w/o validation (we can add package before name,... is
    # set)
    @tpl.save_xml!
  end

  def check_permission
    require_privilege(Privilege::IMAGE_MODIFY)
  end

  def get_selected_id
    ids = params[:ids].to_a
    if ids.size != 1
      raise "No template is selected" if ids.empty?
      raise "You can select only one template" if ids.size > 1
    end
    return ids.first
  end
end
