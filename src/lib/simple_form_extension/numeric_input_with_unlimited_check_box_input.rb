class NumericInputWithUnlimitedCheckBoxInput < SimpleForm::Inputs::NumericInput


  def input
    numeric_value = object.attributes[attribute_name.to_s]
    check_box_name = options[:check_box_name] || 'unlimited_quota'

    input_html_options[:disabled] = !numeric_value.present?
    input_html_options[:placeholder] = "\u221E"
    input_html = super

    if options[:wrapper_html].present?
      options[:wrapper_html].merge!(:class => 'checkbox inline')
    else
      options[:wrapper_html] = { :class => 'checkbox inline' }
    end

    input_html += template.content_tag(:div, :class => 'control') do
      template.check_box_tag(check_box_name, 1, !numeric_value.present?) +
        template.label_tag(check_box_name, I18n.t('unlimited'), :class => 'control_label')
    end
  end

end
