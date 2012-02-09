module DeployablesHelper
  def image_valid?(assembly)
    edit_xml_path = edit_polymorphic_path([@catalog, @deployable], :edit_xml => true)

    if @missing_images.empty? && assembly[:hwp_name].present?
      link_to t('.images_valid'), edit_xml_path, :class => 'images_valid', :id => 'edit_xml_button'
    elsif assembly[:hwp_name].nil?
      link_to t('.repair_images'), edit_xml_path, :class => 'repair_images', :id => 'edit_xml_button'
    elsif @missing_images.include?(assembly[:image_uuid])
      link_to t('.repair_images'), edit_xml_path, :class => 'repair_images', :id => 'edit_xml_button'
    else
      link_to t('.images_valid'), edit_xml_path, :class => 'images_valid', :id => 'edit_xml_button'
    end
  end

  def deployable_ready?
    false
  end
end
