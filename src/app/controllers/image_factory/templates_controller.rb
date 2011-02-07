require 'util/repository_manager'

class ImageFactory::TemplatesController < ApplicationController
  before_filter :require_user
  before_filter :set_view_vars, :only => [:index, :show]

  def index
    require_privilege(Privilege::VIEW, Template)
    @params = params
    @search_term = params[:q]
    if @search_term.blank?
      load_templates
      return
    end

    # FIXME: Filter on Permissions
    search = Template.search do
      keywords(params[:q])
    end
    @templates = search.results
  end

  def show
    load_templates
    @tpl = Template.find(params[:id])
    require_privilege(Privilege::VIEW, @tpl)
    @url_params = params.clone
    @tab_captions = ['Properties', 'Images']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    load_images(@tpl) if @details_tab == 'images'
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

  def new
    check_create_permission
    # can't use @template variable - is used by compass (or something other)
    @tpl = Template.new(params[:tpl])
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
  end

  def add_selected
    if params[:tpl] and not params[:tpl][:id].blank?
      @tpl = Template.find(params[:tpl][:id])
      check_edit_permission
      @tpl.attributes = params[:tpl]
    else
      @tpl = Template.new(params[:tpl])
      check_create_permission
    end
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    @tpl.add_software(params[:packages].to_a + params[:selected_packages].to_a + params[:cached_packages].to_a,
                      params[:groups].to_a + params[:selected_groups].to_a)
    render :action => @tpl.id ? :edit : :new
  end

  def edit
    @tpl = Template.find(params[:id])
    check_edit_permission
    @tpl.attributes = params[:tpl] unless params[:tpl].blank?
    @tpl.add_software(params[:packages].to_a, params[:groups].to_a)
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
  end

  def create
    check_create_permission
    @tpl = Template.new(params[:tpl])
    @tpl.packages = params[:packages]
    if @tpl.save
      @tpl.assign_owner_roles(current_user)
      flash[:notice] = "Template saved."
      @tpl.set_complete
      redirect_to image_factory_templates_path
    else
      @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
      render :new
    end
  end

  def update
    @tpl = Template.find(params[:id])
    check_edit_permission
    @tpl.packages = []
    @tpl.add_software(params[:packages].to_a, params[:groups].to_a)

    if @tpl.update_attributes(params[:tpl])
      @tpl.set_complete
      flash[:notice] = "Template updated."
      redirect_to image_factory_templates_path
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
      render 'search_packages'
    end
  end

  def metagroup_packages
    set_package_vars
    group = params[:__rewrite] ? params[:__rewrite][:metagroup_packages] : nil
    @metagroup_packages = @repository_manager.metagroup_packages(group)
    if request.xhr?
      render :partial => 'metagroup_packages'
    end
  end

  def collections
    if params[:package_search_button]
      search_packages
      return
    end
    set_package_vars
    @collections = @repository_manager.groups
    if request.xhr?
      render :partial => 'collections'
    end
  end

  def content_selection
    set_package_vars(true)
    @collections = @repository_manager.groups
    if request.xhr?
      render :partial => 'software_selection', :locals => {:view => 'collections'}
    else
      render :collections
    end
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

  def assembly
    # FIXME: do we need perm check here?
  end

  def deployment_definition
    # FIXME: do we need perm check here?
    @all_targets = Image.available_targets
  end

  def remove_package
    params[:packages].delete(params[:name]) unless params[:name].blank?
    if params[:tpl] and not params[:tpl][:id].blank?
      @tpl = Template.find(params[:tpl][:id])
      check_edit_permission
      @tpl.attributes = params[:tpl]
    else
      @tpl = Template.new(params[:tpl])
      check_create_permission
    end
    @tpl.add_software(params[:packages].to_a, params[:groups].to_a)
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    render :action => @tpl.id ? :edit : :new
  end

  def multi_destroy
    Template.find(params[:selected]).each do |template|
      if check_privilege(Privilege::MODIFY, template)
        template.destroy
     else
        flash[:error] = "You don't have a permission to delete."
     end
    end
    redirect_to image_factory_templates_url
  end

  protected

  def load_images(tpl)
    @images_header = [
      {:name => 'NAME', :sort_attr => 'templates.name'},
      {:name => 'OS', :sort_attr => 'templates.platform'},
      {:name => 'VERSION', :sort_attr => 'templates.platform_version'},
      {:name => 'ARCH', :sort_attr => 'templates.architecture'},
      {:name => 'STATUS', :sort_attr => 'status'},
    ]
    @images = tpl.images
  end

  def set_view_vars
    @header = [
      {:name => 'NAME', :sort_attr => 'name'},
      {:name => 'OS', :sort_attr => 'platform'},
      {:name => 'VERSION', :sort_attr => 'platform_version'},
      {:name => 'BOOTABLE', :sortable => false},
      {:name => 'ARCH', :sort_attr => 'architecture'},
    ]

    @url_params = params.clone
  end

  def load_templates
    @templates = Template.list_for_user(current_user,
                                        Privilege::VIEW,
                                        :include => :images,
                                        :order => get_order('name')
                                        )
  end

  def set_package_vars(set_all = false)
    id = params[:id] || (params[:tpl] && params[:tpl][:id]) || nil
    if id.blank?
      @tpl = Template.new
      check_create_permission
    else
      @tpl = Template.find(id)
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
