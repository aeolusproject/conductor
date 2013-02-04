module SimpleForm
  module Components

    module Notes
      def note
        @note ||= begin
          note_text = options[:note]
          note_text = note_text.is_a?(String) ? note_text : translate(:notes)
          if note_text.present?
            template.content_tag('strong', _('Note:')) + ' ' + note_text
          end
        end
      end
    end

  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::Notes)
