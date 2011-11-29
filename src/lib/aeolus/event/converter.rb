module Aeolus
  module Event
    class Converter
      attr_accessor :output, :formatted_msg
      def transform(event)
        @formatted_msg= ""
        event.attributes.each do |attribute|
          @formatted_msg<< "#{attribute}=#{format_value(event.send(attribute))} "
        end
        return true
      end
      private
      def format_value(val)
        if val.nil?
          val = ""
        elsif val.split.size > 1
          val = "\"#{val}\""
        end
        return val
      end
    end
  end
end
