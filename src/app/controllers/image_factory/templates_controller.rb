require 'util/repository_manager'

class ImageFactory::TemplatesController < ApplicationController
  before_filter :require_user
  before_filter :check_permission, :except => [:index, :show]
  before_filter :load_templates, :only => [:index, :show]

  def index
  end

  def show
    @tpl = Template.find(params[:id])
    @url_params = params.clone
    @tab_captions = ['Properties']
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

  def new
    # can't use @template variable - is used by compass (or something other)
    @tpl = Template.new(params[:tpl])
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    @tpl.add_software(params[:packages].to_a + params[:selected_packages].to_a + params[:cached_packages].to_a,
                      params[:groups].to_a + params[:selected_groups].to_a)
    render :action => :new
  end

  def edit
    @tpl = Template.find(params[:id])
    @tpl.attributes = params[:tpl] unless params[:tpl].blank?
    @repository_manager = RepositoryManager.new(:repositories => params[:repository] || @tpl.platform)
    render :action => :edit
  end

  def create
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
    @tpl = params[:template_id].blank? ? Template.new : Template.find(params[:template_id])
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
        t.destroy
        unless t.destroyed?
          errs[t.name] = t.errors.full_messages.join(". ")
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
  end

  def deployment_definition
    @all_targets = Image.available_targets
  end

  protected

  def load_templates
    @header = [
      {:name => 'NAME', :sort_attr => 'name'},
      {:name => 'OS', :sort_attr => 'platform'},
      {:name => 'VERSION', :sort_attr => 'platform_version'},
      {:name => 'BOOTABLE', :sortable => false},
      {:name => 'ARCH', :sort_attr => 'architecture'},
    ]

    # TODO: add template permission check
    require_privilege(Privilege::IMAGE_VIEW)
    @templates = Template.find(
      :all,
      :include => :images,
      :order => get_order('name')
    )
    @url_params = params.clone
  end

  def set_package_vars(set_all = false)
    @tpl = params[:id].blank? ? Template.new : Template.find(params[:id])
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

  def check_permission
    require_privilege(Privilege::IMAGE_MODIFY)
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
