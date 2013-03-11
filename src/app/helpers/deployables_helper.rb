module DeployablesHelper
  def image_valid?(assembly, modify_perm)
    edit_xml_path = edit_polymorphic_path([@catalog, @deployable], :edit_xml => true)

    if @missing_images.empty? && assembly[:hwp_name].present?
      link_hash = {:label => '.images_valid', :class => 'images_valid'}
    elsif assembly[:hwp_name].nil?
      link_hash = {:label => '.repair_images', :class => 'repair_images'}
    elsif @missing_images.include?(assembly[:image_uuid])
      link_hash = {:label => '.repair_images', :class => 'repair_images'}
    else
      link_hash = {:label => '.images_valid', :class => 'images_valid'}
    end
    if modify_perm
      link_to(t(link_hash[:label]), edit_xml_path,
              :class => link_hash[:class], :id => 'edit_xml_button')
    else
      content_tag(:a, t(link_hash[:label]), :class => link_hash[:class],
                  :id => 'edit_xml_button')
    end
  end

  def deployable_ready?
    false
  end

  def translate_build_status(status)
    case status
      when :not_build
        _("Images are not built")
      when :building
        _("Images are being built.")
      when :pushing
        _("Images are being pushed.")
      when :not_pushed
        _("Some of the images are not pushed")
      when :pushed
        _("All Images are pushed and recent.")
      else
        status
    end
  end
end
