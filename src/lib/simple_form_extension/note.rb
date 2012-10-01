module SimpleForm
  module Components

    module Notes
      def note
        @note ||= begin
          if options[:note].present?
            template.content_tag('strong', I18n.t('simple_form.notes.note_label')) + ' ' + options[:note]
          end
        end
      end
    end

  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::Notes)
