class BuildsController < ApplicationController
  before_filter [:require_user], :except => [:update_status]

  def index
  end

  def create
    @tpl = LegacyTemplate.find(params[:legacy_template_id])
    check_permission

    errors = {}
    warnings = []
    begin
      target = ProviderType.find(params[:target])
      LegacyImage.create_and_build!(@tpl, target)
    rescue
      flash[:error] = "Warning: #{$!.message}"
      logger.error $!.message
      logger.error $!.backtrace.join("\n   ")
    end
    redirect_to legacy_template_path(@tpl, :details_tab => 'builds')
  end

  def upload
    @tpl = LegacyTemplate.find(params[:template_id])
    pimg = LegacyProviderImage.create!(
      :legacy_image => LegacyImage.find(params[:image_id]),
      :provider => Provider.find(params[:provider_id]),
      :status => LegacyProviderImage::STATE_QUEUED
    )
    Delayed::Job.enqueue(PushJob.new(pimg.id))
    redirect_to legacy_template_path(@tpl, :details_tab => 'builds')
  end

  def delete
    @tpl = LegacyTemplate.find(params[:template_id])
    # FIXME: add logic to delete image when v2 image factory lands
    redirect_to legacy_template_path(@tpl, :details_tab => 'builds')
  end

  def edit
    # FIXME: is @tpl defined here? do we need check_permission here?
  end

  def update
    # FIXME: is @tpl defined here? do we need check_permission here?
  end

  def retry
    @tpl = LegacyTemplate.find(params[:legacy_template_id])
    check_permission
    begin
      if params[:legacy_image_id]
        image = LegacyImage.find(params[:legacy_image_id])
        if image
          errors = {}
          warnings = []
          image.rebuild!
          flash[:notice] = "Queued rebuild for image #{image.name}"
        else
          flash[:warning] = "could not find image #{image_id}"
        end
      elsif params[:provider_image_id]
        provider_image = LegacyProviderImage.find(params[:provider_image_id])
        if provider_image
          provider_image.retry_upload!
          flash[:notice] = "Queued upload of provider image #{provider_image.image.name} to #{provider_image.provider.name}"
        else
          flash[:warning] = "could not find provider image #{provider_image_id}"
        end
      else
        flash[:warning] = 'You need to specify either a provider or a provider image'
      end
    rescue
      flash[:warning] = $!.message
      logger.error $!.message
      logger.error $!.backtrace.join("\n   ")
    end
    redirect_to legacy_template_path(@tpl, :details_tab => 'builds')
  end

  def update_status
    image = LegacyImage.find_by_uuid(params[:uuid])
    image = LegacyProviderImage.find_by_uuid(params[:uuid]) unless image

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

  # TODO: DRY this, is used in legacy_templates controller too
  def get_order(default)
    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order_field = params[:order_field] || default
    "#{@order_field} #{@order_dir}"
  end

  def check_permission
    require_privilege(Privilege::MODIFY, @tpl)
  end
end
