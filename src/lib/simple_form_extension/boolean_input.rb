class BooleanInput <  SimpleForm::Inputs::BooleanInput

  def input
    if options[:wrapper_html].present?
      options[:wrapper_html].merge!(:class => 'checkbox')
    else
      options[:wrapper_html] = { :class => 'checkbox' }
    end

    super
  end

end
