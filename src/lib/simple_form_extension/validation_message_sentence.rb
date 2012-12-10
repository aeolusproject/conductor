module SimpleForm
  module Components

    module ValidationMessageSentence

      def validation_message_sentence
        error_text if has_errors?
      end

      def has_errors?
        object && object.respond_to?(:errors) && errors.present?
      end

      protected

      def error_text
        "#{options[:error_prefix]} #{errors.first.capitalize}.".lstrip.html_safe
      end

      def errors
        @errors ||= (errors_on_attribute + errors_on_association).compact
      end

      def errors_on_attribute
        object.errors[attribute_name]
      end

      def errors_on_association
        reflection ? object.errors[reflection.name] : []
      end

    end

  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::ValidationMessageSentence)
