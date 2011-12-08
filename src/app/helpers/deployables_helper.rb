module DeployablesHelper
  def image_ready?(assembly)
    if @missing_images.empty? && assembly[:hwp_name].present?
      link_to t('.images_ready'), edit_catalog_deployable_path(@catalog, @deployable, :edit_xml => true), :class => 'images_ready', :id => 'edit_xml_button'
    elsif assembly[:hwp_name].nil?
      link_to t('.repair_images'), edit_catalog_deployable_path(@catalog, @deployable, :edit_xml => true), :class => 'repair_images', :id => 'edit_xml_button'
    elsif @missing_images.include?(assembly[:image_uuid])
      link_to t('.repair_images'), edit_catalog_deployable_path(@catalog, @deployable, :edit_xml => true), :class => 'repair_images', :id => 'edit_xml_button'
    else
      link_to t('.images_ready'), edit_catalog_deployable_path(@catalog, @deployable, :edit_xml => true), :class => 'images_ready', :id => 'edit_xml_button'
    end
  end

  def deployable_ready?
    false
  end
end
