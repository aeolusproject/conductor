class InformativeInput < SimpleForm::Inputs::Base

  def input
    if options[:wrapper_html].present?
      options[:wrapper_html].merge!(:class => 'informative')
    else
      options[:wrapper_html] = {:class => 'informative'}
    end

    template.content_tag :span, :class => input_html_classes do
      options[:text]
    end
  end

  def input_html_classes
    super.push('value') unless super.include?('value')

    super
  end

end
