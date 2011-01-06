require 'util/repository_manager'

class TemplatesController < ApplicationController
  before_filter :require_user
  layout :layout

  def layout
    return "aggregator" unless request.xhr?
  end

  def section_id
    'build'
  end

  def index
    @templates = Template.list_for_user(current_user,
                                        Privilege::VIEW,
                                        :include => :images,
                                        :order => get_order('name'))
  end

  def index_action
    if params[:new_template]
      redirect_to new_template_path
    elsif params[:assembly]
      redirect_to assembly_template_path(:id => params[:ids].to_a.first)
    elsif params[:deployment_definition]
      redirect_to deployment_definition_template_path(:id => params[:ids].to_a.first)
    elsif params[:delete]
      redirect_to destroy_multiple_templates_path(:ids => params[:ids].to_a)
    elsif params[:edit]
      if id = get_selected_id
        redirect_to edit_template_path(:id => id)
      else
        redirect_to templates_path
      end
    elsif params[:build]
      if id = get_selected_id
        redirect_to new_build_path(:template_id => id)
      else
        redirect_to templates_path
      end
    else
      raise 'Unknown action'
    end
  end

  # Since the template form submission can mean multiple things,
  # we dispatch based on form parameters here
  def dispatch
    if params[:save]
      create
    elsif params[:cancel]
      redirect_to templates_path
    elsif params[:add_software_form]
      collections
    elsif params[:collections]
      collections
    elsif pkg = params.keys.find { |k| k =~ /^remove_package_(.*)$/ }
      # actually remove the package from list
      params[:packages].delete($1) if params[:packages]
      new
    elsif params[:add_selected]
      new
    elsif params[:cancel_add_software]
      params[:selected_packages] = params[:packages]
      params[:selected_groups] = params[:groups]
      params[:cached_packages] = []
      new
    elsif params.include?('metagroup_packages')
      metagroup_packages
    elsif params[:package_search]
      search_packages
    else
      raise "unknown action"
    end
  end

  def new
    check_create_permission
    # can't use @template variable - is used by compass (or something other)
    @tpl = Template.new(params[:tpl])
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    @tpl.add_software(params[:packages].to_a + params[:selected_packages].to_a + params[:cached_packages].to_a,
                      params[:groups].to_a + params[:selected_groups].to_a)
    render :action => :new
  end

  def edit
    @tpl = Template.find(params[:id])
    check_edit_permission
    @tpl.attributes = params[:tpl] unless params[:tpl].blank?
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    render :action => :edit
  end

  def create
    check_create_permission
    @tpl = Template.new(params[:tpl])
    @tpl.packages = params[:packages]
    if @tpl.save
      flash[:notice] = "Template saved."
      @tpl.set_complete
      redirect_to templates_path
    else
      @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
      render :action => 'new'
    end
  end

  def update
    @tpl = Template.find(params[:id])
    @tpl.packages = []
    check_edit_permission

    if @tpl.update_attributes(params[:tpl])
      @tpl.set_complete
      flash[:notice] = "Template updated."
      redirect_to templates_path
    else
      @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
      render :action => 'edit'
    end
  end

  def search_packages
    set_package_vars
    @page = get_page
    @cached_packages = params[:cached_packages].to_a + params[:selected_packages].to_a
    @searched_packages = params[:package_search].empty? ? [] : @repository_manager.search_package(
      params[:package_search]).paginate(:page => @page, :per_page => 60)
    if request.xhr?
      render :partial => 'search_packages'
    else
      render :search_packages
    end
  end

  def metagroup_packages
    set_package_vars
    @metagroup_packages = @repository_manager.metagroup_packages(params[:metagroup_packages])
    if request.xhr?
      render :partial => 'metagroup_packages'
    else
      render :metagroup_packages
    end
  end

  def collections
    set_package_vars
    @collections = @repository_manager.groups
    if request.xhr?
      render :partial => 'collections'
    else
      render :collections
    end
  end

  def content_selection
    set_package_vars(true)
    @collections = @repository_manager.groups
    render :collections
  end

  def managed_content
    if params[:template_id].blank?
      @tpl = Template.new
      check_create_permission
    else
      @tpl = Template.find(params[:template_id])
      check_edit_permission
    end
    @tpl.add_software(params[:packages].to_a + params[:selected_packages].to_a,
                      params[:groups].to_a + params[:selected_groups].to_a)
    render :layout => false
  end

  def destroy_multiple
    ids = params[:ids].to_a
    if ids.empty?
      flash[:notice] = "No Template Selected"
    else
      errs = {}
      Template.find(ids).each do |t|
        if check_permission(Privilege::MODIFY, t)
          t.destroy
          errs[t.name] = t.errors.full_messages.join(". ") unless t.destroyed?
        else
          errs[t.name] = "You don't have permission to delete #{t.name}"
        end
      end
      if errs.empty?
        flash[:notice] = 'Template deleted'
      else
        flash_error('Error while deleting template', errs)
      end
    end
    redirect_to templates_path
  end

  def assembly
    # FIXME: do we need perm check here?
  end

  def deployment_definition
    # FIXME: do we need perm check here?
    @all_targets = Image.available_targets
  end

  private

  def set_package_vars(set_all = false)
    if params[:id].blank?
      @tpl = Template.new
      check_create_permission
    else
      @tpl = Template.find(params[:id])
      check_edit_permission
    end
    @tpl.attributes = params[:tpl] unless params[:tpl].nil?
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    @groups = @repository_manager.groups
    @categories = @repository_manager.categories if not request.xhr? or set_all
    @metagroups = @repository_manager.metagroups if not request.xhr? or set_all
    @tpl.add_software(params[:packages].to_a, params[:groups].to_a)
  end

  def get_order(default)
    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order_field = params[:order_field] || default
    "#{@order_field} #{@order_dir}"
  end

  def flash_error(summary, errs)
    flash.now[:error] ||= {}
    flash.now[:error][:summary] = summary
    flash.now[:error][:failures] ||= {}
    flash.now[:error][:failures].merge!(errs)
  end

  def check_create_permission
    require_privilege(Privilege::CREATE, Template)
  end

  def check_edit_permission
    require_privilege(Privilege::MODIFY, @tpl)
  end

  def get_selected_id
    ids = params[:ids].to_a
    if ids.size != 1
      flash[:warning] = ids.empty? ? 'No Template Selected' : 'You can select only one template'
      return
    end
    return ids.first
  end

  def get_page
    if params[:page] == 'Previous'
      return params[:old_page].to_i - 1
    elsif params[:page] == 'Next'
      return params[:old_page].to_i + 1
    else
      return params[:page].blank? ? 1 : params[:page].to_i
    end
  end
end
