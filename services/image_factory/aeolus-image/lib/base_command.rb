module Aeolus
  module Image
    #This will house some methods that multiple Command classes need to use.
    class BaseCommand
      attr_accessor :options
      def initialize(opts={}, logger=nil)
        logger(logger)
        @options = opts
      end

      protected
      def logger(logger=nil)
        @logger ||= logger
        unless @logger
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::INFO
          @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        end
        return @logger
      end

    end
  end
end
