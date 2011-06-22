module Aeolus
  module Image
    class ListCommand < BaseCommand
      def initialize(opts={}, logger=nil)
        super(opts, logger)
      end

      def images
        doc = Nokogiri::XML iwhd['/images'].get
        doc.xpath("/objects/object/key").collect { |node| "uuid: " + node.text }
      end

      def builds
        not_implemented
      end

      def targetimages
        not_implemented
      end

      def targets
        not_implemented
      end

      def providers
        not_implemented
      end

      def accounts
        not_implemented
      end
    end
  end
end
