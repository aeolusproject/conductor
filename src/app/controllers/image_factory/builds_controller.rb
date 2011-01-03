class ImageFactory::BuildsController < ApplicationController
  before_filter [:require_user, :check_permission]

  def new
    raise "select template to build" unless id = params[:template_id]
    @tpl = Template.find(id)
    if @tpl.imported
      flash[:warning] = "Build imported template is not supported"
      redirect_to templates_path
    end
    @all_targets = Image.available_targets
  end

  def create
    @tpl = Template.find(params[:template_id])
    @all_targets = Image.available_targets

    if params[:targets].blank?
      flash.now[:warning] = 'You need to check at least one provider format'
      render :action => 'new'
      return
    end

    @tpl.upload unless @tpl.uploaded
    errors = {}
    warnings = []
    params[:targets].each do |target|
      begin
        Image.build(@tpl, target)
      rescue ImageExistsError
        warnings << $!.message
      rescue
        errors[target] = $!.message
      end
    end
    flash[:warning] = 'Warning: ' + warnings.join unless warnings.empty?
    if errors.empty?
      redirect_to image_factory_template_path(@tpl, :details_tab => 'images')
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

  def check_permission
    require_privilege(Privilege::IMAGE_MODIFY)
  end
end
