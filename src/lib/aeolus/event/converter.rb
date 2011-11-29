module Aeolus
  module Event
    class Converter
      attr_accessor :output, :formatted_msg
      def initialize(out=STDOUT)
        @output = out
      end

      def process(event)
        if transform(event)
          emit
          return true
        end
        return false
      end

      def transform(event)
        @formatted_msg= ""
        event.attributes.each do |attribute|
          @formatted_msg<< "#{attribute}=#{format_value(event.send(attribute))} "
        end
        return true
      end

      def emit
        @output.puts formatted_msg
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
