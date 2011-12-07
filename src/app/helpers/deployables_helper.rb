module DeployablesHelper
  def image_ready?(assembly)
    if @missing_images.empty?
      "image is ready"
    else
      if @missing_images.include?(assembly[:image_uuid])
        "Image specified in xml does not exist"
      else
        "image is ready"
      end
    end
  end
end
