module Aeolus
  module Event
    module Accessor
      def attr_accessor *attrs
        @attrs ||= []
        @attrs << attrs
        super(*attrs)
      end
      def attributes
        @attrs.flatten
      end
    end
  end
end
