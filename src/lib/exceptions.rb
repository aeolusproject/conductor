module Aeolus
  module Conductor
    module API
      class Error < StandardError
        attr_reader :status

        def initialize(status, message = nil)
          @status = status
          @message  = message
        end
      end

      class TargetNotFound < Error; end
      class ProviderAccountNotFound < Error; end
    end
  end
end