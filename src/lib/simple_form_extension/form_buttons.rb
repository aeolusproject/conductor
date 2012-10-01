module SimpleForm

  module FormButtons
    def form_buttons(*args, &block)
      template.content_tag :div, :class => "control_group buttons" do
        template.content_tag :div, :class => "input" do
          options = args.extract_options!
          options[:class] = ['btn primary', options[:class]].compact
          args << options

          if cancel = options.delete(:cancel)
            submit(*args, &block) + template.link_to(I18n.t('simple_form.buttons.cancel'), cancel, :class => 'btn')
          else
            submit(*args, &block)
          end
        end
      end
    end
  end

end

SimpleForm::FormBuilder.send :include, SimpleForm::FormButtons