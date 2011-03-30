class ImageFactory::BuildsController < ApplicationController
  before_filter [:require_user], :except => [:update_status]

  def create
    @tpl = Template.find(params[:template_id])
    check_permission

    errors = {}
    warnings = []
    begin
      target = ProviderType.find(params[:target])
      Image.create_and_build!(@tpl, target)
    rescue
      flash[:error] = "Warning: #{$!.message}"
      logger.error $!.message
      logger.error $!.backtrace.join("\n   ")
    end
    redirect_to image_factory_template_path(@tpl, :details_tab => 'builds')
  end

  def upload
    @tpl = Template.find(params[:template_id])
    pimg = ProviderImage.create!(
      :image => Image.find(params[:image_id]),
      :provider => Provider.find(params[:provider_id]),
      :status => ProviderImage::STATE_QUEUED
    )
    Delayed::Job.enqueue(PushJob.new(pimg.id))
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

  def update_status
    image = Image.find_by_uuid(params[:uuid])
    image = ProviderImage.find_by_uuid(params[:uuid]) unless image

    if image
      image.status = params[:status]
      image.save!
    end
    return head :not_found unless image
    respond_to do |format|
      format.xml {
        render :xml => image.to_xml
      }
    end

  end
  private

  # TODO: DRY this, is used in templates controller too
  def get_order(default)
    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order_field = params[:order_field] || default
    "#{@order_field} #{@order_dir}"
  end

  def check_permission
    require_privilege(Privilege::MODIFY, @tpl)
  end
end
