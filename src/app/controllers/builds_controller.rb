class BuildsController < ApplicationController
  before_filter :require_user

  def section_id
    'build'
  end

  def index
    require_privilege(Privilege::IMAGE_VIEW)
    order = get_order('templates.name')
    @running_images = Image.all(:include => :template, :conditions => ['status IN (?)', Image::ACTIVE_STATES], :order => order)
    @completed_images = Image.all(:include => :template, :conditions => {:status => Image::STATE_COMPLETE}, :order => order)
    @failed_images = Image.all(:include => :template, :conditions => {:status => Image::STATE_FAILED}, :order => order)
  end

  def new
    raise "select template to build" unless id = params[:template_id]
    @tpl = Template.find(id)
    @all_targets = Image.available_targets
  end

  def create
    if params[:cancel]
      redirect_to templates_path
      return
    end

    @tpl = Template.find(params[:template_id])
    @all_targets = Image.available_targets

    if params[:targets].blank?
      flash.now[:warning] = 'You need to check at least one provider format'
      render :action => 'new'
      return
    end

    @tpl.upload_template unless @tpl.uploaded
    errors = {}
    params[:targets].each do |target|
      # FIXME: for beta release we check explicitly that provider and provider
      # account exists
      unless provider = Provider.find_by_cloud_type(target)
        flash_error('Error while trying to build image',
                    'no provider account' => "There is no provider of '#{target}' type, \
you can add provider on <a href=\"#{url_for :controller => 'provider'}\">the providers page.</a>")
        render :action => 'new' and return
      end
      if provider.cloud_accounts.empty?
        flash_error('Error while trying to build image',
                    'no provider account' => "There is no provider account for '#{target}' \
provider, you can add account on <a href=\"#{url_for :controller => 'provider', \
:action => 'accounts', :id => provider.id}\">the provider accounts page</a>")
        render :action => 'new' and return
      end
      begin
        Image.build(@tpl, target)
      rescue
        errors[target] = $!.message
      end
    end
    if errors.empty?
      redirect_to builds_path
    else
      flash_error('Error while trying to build image', errors)
      render :action => 'new'
    end
  end

  def edit
  end

  def update
  end

  private

  # TODO: DRY this, is used in templates controller too
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
end
