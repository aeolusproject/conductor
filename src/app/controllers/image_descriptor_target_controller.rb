class ImageDescriptorTargetController < ApplicationController
  before_filter :require_user

  def cancel
    ImageDescriptorTarget.update(params[:id], :status => ImageDescriptorTarget::STATE_CANCELED)
    redirect_to :controller => 'templates', :action => 'new', :params => {'image_descriptor[id]' => params[:descriptor_id], :tab => 'software'}
  end
end
