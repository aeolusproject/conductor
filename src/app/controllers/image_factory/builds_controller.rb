class ImageFactory::BuildsController < ApplicationController
  before_filter [:require_user]

  def new
    raise "select template to build" unless id = params[:template_id]
    @tpl = Template.find(id)
    check_permission
    if @tpl.imported
      flash[:warning] = "Build imported template is not supported"
      redirect_to image_factory_templates_path
    end
    @all_targets = ProviderType.all(:conditions => {:build_supported => true})
  end

  def create
    @tpl = Template.find(params[:template_id])
    check_permission
    @all_targets = ProviderType.all(:conditions => {:build_supported => true})

    if params[:targets].blank?
      flash.now[:warning] = 'You need to check at least one provider format'
      render :action => 'new'
      return
    end

    @tpl.upload unless @tpl.uploaded
    errors = {}
    warnings = []
    params[:targets].each do |target_id|
      begin
        target = ProviderType.find(target_id)
        Image.build(@tpl, target)
      rescue ImageExistsError
        warnings << $!.message
      rescue
        errors[target ? target.name : target_id] = $!.message
      end
    end
    flash[:warning] = 'Warning: ' + warnings.join unless warnings.empty?
    if errors.empty?
      redirect_to image_factory_template_path(@tpl, :details_tab => 'builds')
    else
      flash_error('Error while trying to build image', errors)
      render :action => 'new'
    end
  end

  def upload
    @tpl = Template.find(params[:template_id])
    # FIXME: add logic to upload image when v2 image factory lands
    redirect_to image_factory_template_path(@tpl, :details_tab => 'builds')
  end

  def delete
    @tpl = Template.find(params[:template_id])
    # FIXME: add logic to delete image when v2 image factory lands
    redirect_to image_factory_template_path(@tpl, :details_tab => 'builds')
  end

  def edit
    # FIXME: is @tpl defined here? do we need check_permission here?
  end

  def update
    # FIXME: is @tpl defined here? do we need check_permission here?
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
    require_privilege(Privilege::MODIFY, @tpl)
  end
end
