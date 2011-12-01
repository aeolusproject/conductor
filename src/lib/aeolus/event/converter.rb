#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
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
        elsif val.respond_to?(:split) && val.split.size > 1
          val = "\"#{val}\""
        end
        return val.to_s
      end
    end
  end
end
