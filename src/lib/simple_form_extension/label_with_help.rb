module SimpleForm
  module Components

    module LabelWithHelp
      def label_with_help
        @label_with_help ||= begin
          label_with_help_content = label

          if options[:help]
            label_with_help_content.insert(0, template.content_tag('i', '?'))
            label_with_help_content.insert(-1, template.content_tag('span', options[:help]))

            if options[:label_wrapper_html].present?
              options[:label_wrapper_html].merge!(:class => 'help')
            else
              options[:label_wrapper_html] = {:class => 'help'}
            end
          end

          label_with_help_content
        end
      end
    end

  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::LabelWithHelp)
