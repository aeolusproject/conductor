require 'syslog'

module Aeolus
  module Event
    class SyslogConverter < Converter
      #attr_accessor :output, :formatted_msg
      def initialize(out=STDOUT)
        super(out)
      end

      def emit
        Syslog.open('aeolus', Syslog::LOG_PID, Syslog::LOG_LOCAL6) do |s|
          s.info"#{formatted_msg}"
        end
      end
    end
  end
end
